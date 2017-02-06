FROM dperson/samba
MAINTAINER Mateusz Górny <divo@divo.net.pl

ADD samba.sh /usr/bin/
ADD smb.conf /etc/samba/smb.conf
ADD samba-homedir.sh /usr/bin/samba-homedir.sh

VOLUME ["/etc/samba"]
VOLUME ["/srv/"]
EXPOSE 137/udp 138/udp 139 445
ENTRYPOINT ["samba.sh"]