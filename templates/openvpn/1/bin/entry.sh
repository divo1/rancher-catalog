#!/bin/bash

CONTINUE=1
function error { echo "Error : $@"; CONTINUE=0; }
function die { echo "$@" ; exit 1; }
function checkpoint { [ "$CONTINUE" = "0" ] && echo "Unrecoverable errors found, exiting ..." && exit 1; }

OPENVPNDIR="$OPENVPN"

# Providing defaults values for missing env variables
[ "$CERT_COMMON_NAME" = "" ] && export CERT_COMMON_NAME="openvpn.server"
[ "$CERT_COUNTRY" = "" ]     && export CERT_COUNTRY="US"
[ "$CERT_PROVINCE" = "" ]    && export CERT_PROVINCE="AL"
[ "$CERT_CITY" = "" ]        && export CERT_CITY="Birmingham"
[ "$CERT_ORG" = "" ]         && export CERT_ORG="ACME"
[ "$CERT_EMAIL" = "" ]       && export CERT_EMAIL="nobody@example.com"
[ "$CERT_OU" = "" ]          && export CERT_OU="IT"
[ "$VPNPOOL_NETWORK" = "" ]  && export VPNPOOL_NETWORK="10.43.0.0"
[ "$VPNPOOL_CIDR" = "" ]     && export VPNPOOL_CIDR="16"
[ "$REMOTE_IP" = "" ]        && export REMOTE_IP="openvpn.divo.net.pl"
[ "$REMOTE_PORT" = "" ]      && export REMOTE_PORT="1194"
[ "$PUSHDNS" = "" ]          && export PUSHDNS="169.254.169.250"
[ "$PUSHSEARCH" = "" ]       && export PUSHSEARCH="rancher.internal"
[ "$DHPARAM_KEY" = "" ]      && export DHPARAM_KEY="2048"

[ "$ROUTE_NETWORK" = "" ]    && export ROUTE_NETWORK="10.42.0.0"
[ "$ROUTE_NETMASK" = "" ]    && export ROUTE_NETMASK="255.255.0.0"

export RANCHER_METADATA_API='push "route 169.254.169.250 255.255.255.255"'
[ "$NO_RANCHER_METADATA_API" != "" ] && export RANCHER_METADATA_API=""

# Checks
[ "${#CERT_COUNTRY}" != "2" ] && error "Certificate Country must be a 2 characters long string only"

checkpoint

env | grep "REMOTE_"

# Saving environment variables

env | grep "REMOTE_" | while read i
do
    var=$(echo "$i" | awk -F= '{print $1}')
    var_data=$( echo "${!var}" | sed "s/'/\\'/g" )
    echo "export $var='$var_data'" >> $OPENVPNDIR/remote.env
done

cdr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

echo "=====[ Generating server config ]=============================================="
VPNPOOL_NETMASK=$(cdr2mask $VPNPOOL_CIDR)

cat > $OPENVPNDIR/server.conf <<- EOF

server $VPNPOOL_NETWORK $VPNPOOL_NETMASK
port $REMOTE_PORT
proto udp
dev tap
dh $EASYRSA_PKI/dh.pem
push "dhcp-option DNS $PUSHDNS"
push "dhcp-option SEARCH $PUSHSEARCH"
push "route $ROUTE_NETWORK $ROUTE_NETMASK"
client-to-client
link-mtu 1500
ca $EASYRSA_PKI/ca.crt
cert $EASYRSA_PKI/issued/$CERT_COMMON_NAME.crt
key $EASYRSA_PKI/private/$CERT_COMMON_NAME.key
tls-auth $EASYRSA_PKI/ta.key 0
cipher AES-256-CBC
auth SHA1
$RANCHER_METADATA_API
keepalive 10 120
comp-lzo
persist-key
persist-tun
#username-as-common-name
#client-cert-not-required

script-security 3 system
#auth-user-pass-verify /usr/local/bin/openvpn-auth.sh via-env

EOF

echo $OPENVPN_EXTRACONF | sed 's/\\n/\n/g' >> $OPENVPNDIR/server.conf

mkdir -p /dev/net
if [ ! -c /dev/net/tap ]; then
    mknod /dev/net/tap c 10 200
fi

#mkdir -p /dev/net
#if [ ! -c /dev/net/tun ]; then
#    mknod /dev/net/tun c 10 200
#fi

echo "=====[ Generating certificates ]==============================================="
if [ ! -d $OPENVPNDIR/easy-rsa ]; then
   # Copy easy-rsa tools to /etc/openvpn
   rsync -avz /usr/share/easy-rsa $OPENVPNDIR/
   cp -R /usr/share/easy-rsa $OPENVPNDIR/

   pushd $OPENVPNDIR/easy-rsa
   cd $OPENVPNDIR/easy-rsa
   checkpoint
   easyrsa init-pki || error "Cannot init pki"
   checkpoint
   echo -en "$CERT_COUNTRY\n" | easyrsa build-ca nopass || error "Cannot build certificate authority"
   checkpoint
   easyrsa build-server-full "$CERT_COMMON_NAME" nopass || error "Cannot create server key"
   checkpoint
   easyrsa gen-dh || error "Cannot create dh file"
   checkpoint
   openvpn --genkey --secret $EASYRSA_PKI/ta.key
   popd
fi

echo "=====[ Enable tcp forwarding and add iptables MASQUERADE rule ]================"
[ -z "$OVPN_NATDEVICE" ] && OVPN_NATDEVICE=eth0
# Setup NAT forwarding if requested
if [ "$OVPN_DEFROUTE" != "0" ] || [ "$OVPN_NAT" == "1" ] ; then
    iptables -t nat -C POSTROUTING -s $OVPN_SERVER -o $OVPN_NATDEVICE -j MASQUERADE || {
      iptables -t nat -A POSTROUTING -s $OVPN_SERVER -o $OVPN_NATDEVICE -j MASQUERADE
    }
    for i in "${OVPN_ROUTES[@]}"; do
        iptables -t nat -C POSTROUTING -s "$i" -o $OVPN_NATDEVICE -j MASQUERADE || {
          iptables -t nat -A POSTROUTING -s "$i" -o $OVPN_NATDEVICE -j MASQUERADE
        }
    done
fi
ip -6 route show default 2>/dev/null
if [ $? = 0 ]; then
    echo "Enabling IPv6 Forwarding"
    # If this fails, ensure the docker container is run with --privileged
    # Could be side stepped with `ip netns` madness to drop privileged flag

    sysctl -w net.ipv6.conf.default.forwarding=1 || echo "Failed to enable IPv6 Forwarding default"
    sysctl -w net.ipv6.conf.all.forwarding=1 || echo "Failed to enable IPv6 Forwarding"
fi


#/usr/local/bin/openvpn-get-client-config.sh > $OPENVPNDIR/client.conf

echo "=====[ OpenVPN Server config ]================================================="
cat $OPENVPNDIR/server.conf
echo "==============================================================================="

echo "=====[ OpenVPN Client config ]================================================="
echo " To regenerate client config, run the 'openvpn-get-client-config.sh' script "
#echo "--------------------------------------------------------------------------"
#cat $OPENVPNDIR/client.conf
echo ""
echo "==============================================================================="
echo "=====[ Starting OpenVPN server ]==============================================="
/usr/sbin/openvpn --cd $OPENVPN --config server.conf