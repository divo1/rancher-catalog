#!/bin/sh

/usr/bin/add-user.sh $SAMBA_ARGS
smbd -F -S -s /config/smb.conf
