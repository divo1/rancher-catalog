#!/bin/bash

function help() {
	echo "Usage: $0 container-name backup-path"
	exit 0
}

if [ -z $1 ]; then
	help
fi

if [ -z $2 ]; then
	help
fi

containerId=$1
path=$2
imageName=$(docker inspect -f '{{ .Image }}' $containerId | awk -F":" '{ print $2 }')
volumes=$(docker inspect -f '{{ range .Mounts }}{{ .Name }}:{{ .Source }}:{{ .Destination }};{{ end }}' $1 | tr ';' '\n')

for a in $volumes; do
	name=$(echo $a | awk -F":" '{ print $1 }')
	source=$(echo $a | awk -F":" '{ print $2 }')
	destination=$(echo $a | awk -F":" '{ print $3 }')
	echo $imageName" - "$name" - "$source" - "$destination
done
#volumes=$(getVolume $containerId)
#echo $volumes

#docker run --rm --volumes-from dbstore -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata