#!/bin/sh

/usr/bin/add-user.sh $SAMBA_ARGS
/usr/bin/supervisord -c /config/supervisord.conf