#!/bin/sh

/usr/bin/add-user.sh $1
/usr/bin/supervisord -c /config/supervisord.conf