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

	cd {{ openvpn_dir }}/easy-rsa
	source vars
	export EASY_RSA="{{ openvpn_dir }}/easy-rsa"
	export KEY_DIR="{{ openvpn_dir }}/easy-rsa/certs"

	./build-key $name

	path="{{ openvpn_dir }}/certs/$name.ovpn"
	cp {{ openvpn_dir }}/default.ovpn $path

	serverconf=$(grep -nirl "port $port" {{ openvpn_dir }})
	proto=$(grep "proto " $serverconf | cut -d" " -f2)
	dev=$(grep "dev " $serverconf | cut -d" " -f2)
	dhPath=$(grep "dh " $serverconf | cut -d" " -f2)
	cipher=$(grep "cipher " $serverconf | cut -d" " -f2)
	tlsAuthPath=$(grep "tls-auth " $serverconf | cut -d" " -f2)

	sed -i "s/__dev__/$dev/g" $path
	sed -i "s/__proto__/$proto/g" $path
	sed -i "s/__server__/$server/g" $path
	sed -i "s/__port__/$port/g" $path
	sed -i "s/__cipher__/$cipher/g" $path
	
	echo "" >> $path
	echo "" >> $path
	echo "<ca>" >> $path
	#cat $EASY_RSA/certs/ca.crt >> $path
	cat {{ openvpn_dir }}/certs/ca.crt >> $path
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
