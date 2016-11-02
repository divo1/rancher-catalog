#!/bin/bash
# /etc/openvpn/generate_client
#
# Generate client to openvpn
#
# @author Mateusz Górny

openvpn_dir="/etc/openvpn"

function generate {
	name=$1
	path="$openvpn_dir/clients/$name.ovpn"
	cat $path

	exit 0
}

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
function help {
	echo "Usage: " $1 " client_name"
}

[ $# -eq 1 ] && generate $1 || help $me
exit 0