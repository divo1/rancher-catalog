#!/bin/bash
# /etc/openvpn/generate_client
#
# Generate client to openvpn
#
# @author Mateusz Górny

openvpn_dir="/etc/openvpn"

function generate {
	name=$1
	port=1194
	server="openvpn.divo.net.pl"
	
	mkdir -p $openvpn_dir/clients/

	path="$openvpn_dir/clients/$name.ovpn"

	cd $openvpn_dir/easy-rsa
	export EASY_RSA="$openvpn_dir/easy-rsa"
	export KEY_DIR="$openvpn_dir/pki/"

	easyrsa --batch --pki-dir=$KEY_DIR build-client-full $name nopass

	serverconf=$(grep -nirl "port $port" $openvpn_dir)
	proto=$(grep "proto " $serverconf | cut -d" " -f2)
	dev=$(grep "dev " $serverconf | cut -d" " -f2)
	dhPath=$(grep "dh " $serverconf | cut -d" " -f2)
	cipher=$(grep "cipher " $serverconf | cut -d" " -f2)
	tlsAuthPath=$(grep "tls-auth " $serverconf | cut -d" " -f2)
	
	echo "client" > $path
	echo "dev $dev" >> $path
	echo "proto $proto" >> $path
	echo "remote $server $port" >> $path
	echo "resolv-retry infinite" >> $path
	echo "nobind" >> $path
	echo "persist-key" >> $path
	echo "persist-tun" >> $path
#	echo "ns-cert-type server" >> $path
	echo "comp-lzo" >> $path
	echo "verb 3" >> $path
	echo "user nobody" >> $path
	echo "group nogroup" >> $path
	echo "cipher $cipher" >> $path
	echo "key-direction 1" >> $path
	echo "" >> $path
	echo "script-security 2" >> $path
	echo "up /etc/openvpn/update-resolv-conf" >> $path
	echo "down /etc/openvpn/update-resolv-conf" >> $path
	echo "" >> $path
	echo "" >> $path
	echo "<ca>" >> $path
	cat $KEY_DIR/ca.crt >> $path
	echo "</ca>" >> $path
	echo "<cert>" >> $path
	cat $KEY_DIR/issued/$name.crt >> $path
	echo "</cert>" >> $path
	echo "<key>" >> $path
	cat $KEY_DIR/private/$name.key >> $path
	echo "</key>" >> $path
	echo "<dh>" >> $path
	cat $dhPath >> $path
	echo "</dh>" >> $path
	echo "<tls-auth>" >> $path
	cat $tlsAuthPath >> $path
	echo "</tls-auth>" >> $path
	
	cat $path

	exit 0
}

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
function help {
	echo "Usage: " $1 " client_name"
}

[ $# -eq 1 ] && generate $1 || help $me
exit 0
