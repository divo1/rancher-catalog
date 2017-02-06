FROM dperson/samba
MAINTAINER Mateusz Górny <divo@divo.net.pl>

RUN  addgroup smbgroup && \
	mkdir -p /srv/shares/home && \
	mkdir -p /srv/shares/public && \
	chmod 0770 /srv/shares/public && \
	chown smbuser.smbgroup /srv/shares/public && \
	chown smbuser.smbgroup /srv/shares/home

ADD samba.sh /usr/bin/
ADD smb.conf /etc/samba/smb.conf
ADD samba-homedir.sh /usr/bin/samba-homedir.sh

RUN chmod +x /usr/bin/samba.sh
RUN chmod +x /usr/bin/samba-homedir.sh
RUN chown smbuser.smbgroup /etc/samba/smb.conf

USER smbuser

EXPOSE 137/udp 138/udp 139 445
CMD ["samba.sh"]
VOLUME ["/srv/shares/public/", "/srv/shares/home/"]
