# Original credit: https://github.com/kylemanna/docker-openvpn/

# Smallest base image
#FROM alpine:3.4
FROM ubuntu:precise

MAINTAINER Mateusz Górny <divo@divo.net.pl>

#RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
#    echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
#    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
#RUN  ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin
RUN cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/ /etc/openvpn/easy-rsa/
#    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

RUN echo deb http://archive.ubuntu.com/ubuntu/ precise main universe > /etc/apt/sources.list.d/precise.list
RUN apt-get update -q
RUN apt-get install -qy openvpn iptables curl

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["/usr/local/bin/entry.sh"]

ADD ./bin /usr/local/bin
#RUN chmod a+x /usr/local/bin/*
RUN chmod a+x /usr/local/bin/*.sh
