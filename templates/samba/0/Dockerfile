FROM alpine:latest

LABEL authors="Peter Winter <peter@pwntr.com>, Mateusz Górny <divo@divo.net.pl"
LABEL Description="Simple and lightweight Samba docker container, based on Alpine Linux." Version="0.1"

RUN apk update && apk upgrade
RUN apk add samba samba-common-tools supervisor && rm -rf /var/cache/apk/*
RUN mkdir /config /shared

COPY *.conf /config/
COPY samba-homedir.sh /usr/bin/samba-homedir.sh
COPY add-user.sh /usr/bin/add-user.sh
COPY start.sh /usr/bin/start.sh

RUN chmod +x /usr/bin/samba-homedir.sh
RUN chmod +x /usr/bin/add-user.sh
RUN chmod +x /usr/bin/start.sh

RUN addgroup -g 1000 smb && adduser -D -H -G smb -s /bin/false -u 1000 smb

RUN mkdir -p -m 775 /srv/shares/public && mkdir -p -m 775 /srv/shares/home
RUN chown smb.smb /srv/shares/public /srv/shares/home

VOLUME /config /shared

EXPOSE 137/udp 138/udp 139 445

ENTRYPOINT ["/usr/bin/start.sh", "$SAMBA_ARGS"]