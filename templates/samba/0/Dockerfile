FROM dperson/samba
MAINTAINER Mateusz Górny <divo@divo.net.pl>

RUN addgroup smbgroup
RUN mkdir -p /srv/shares/home
RUN mkdir -p /srv/shares/public

RUN chown smbuser.smbgroup /srv/shares/public
RUN chown smbuser.smbgroup /srv/shares/home

ADD samba.sh /usr/bin/
ADD smb.conf /etc/samba/smb.conf
ADD samba-homedir.sh /usr/bin/samba-homedir.sh

RUN chmod +x /usr/bin/samba.sh
RUN chmod +x /usr/bin/samba-homedir.sh
RUN chmod 0770 /srv/shares/public
RUN chown smbuser.smbgroup /etc/samba/smb.conf

EXPOSE 137/udp 138/udp 139 445
CMD ["samba.sh"]