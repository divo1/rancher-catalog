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
containerName=$(docker inspect -f '{{ .Name }}' $containerId)
volumes=$(docker inspect -f '{{ range .Mounts }}{{ .Source }}:{{ .Destination }};{{ end }}' $containerId | tr ';' '\n')

echo "Start backup $containerName"
for a in $volumes; do
	source=$(echo $a | awk -F":" '{ print $1 }')
	destination=$(echo $a | awk -F":" '{ print $2 }')
	echo $imageName" - "$containerName" - "$source" - "$destination
done

#volumes=$(getVolume $containerId)

#echo $volumes

#docker run --rm --volumes-from dbstore -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata