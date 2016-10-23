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

	path="$name.ovpn"

	cd $openvpn_dir/easy-rsa
	source vars
	export EASY_RSA="$openvpn_dir/easy-rsa"
	export KEY_DIR="$openvpn_dir/easy-rsa/keys"

	./build-key $name

        serverconf=$(grep -nirl "port $port" {{ openvpn_dir }})
        proto=$(grep "proto " $serverconf | cut -d" " -f2)
        dev=$(grep "dev " $serverconf | cut -d" " -f2)
        dhPath=$(grep "dh " $serverconf | cut -d" " -f2)
        cipher=$(grep "cipher " $serverconf | cut -d" " -f2)
        tlsAuthPath=$(grep "tls-auth " $serverconf | cut -d" " -f2)

cat > $path <<- EOF
client
dev $dev
proto $proto
remote $server $port
resolv-retry infinite
nobind
persist-key
persist-tun
ns-cert-type server
comp-lzo
verb 3
user nobody
group nogroup
cipher $cipher

key-direction 1
EOF


	echo "" >> $path
	echo "" >> $path
	echo "<ca>" >> $path
	#cat $EASY_RSA/certs/ca.crt >> $path
	cat $KEY_DIR/ca.crt >> $path
	echo "</ca>" >> $path
	echo "<cert>" >> $path
	cat $KEY_DIR/$name.crt >> $path
	echo "</cert>" >> $path
	echo "<key>" >> $path
	cat $KEY_DIR/$name.key >> $path
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
