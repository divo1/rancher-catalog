#!/bin/bash

# Automatically create Samba user's home directory
mkdir -m 700 -p /srv/shares/home/${1}
chown ${1}.smbgroup /srv/shares/home/${1}

exit 0
