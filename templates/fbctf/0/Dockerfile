FROM alpine:3.4
LABEL maintainer="Mateusz Górny <divo@divo.net.pl>"

RUN apt-get update
RUN apt-get install git
RUN git clone https://github.com/facebook/fbctf /root/fbctf
RUN cd /root/fbctf && /root/fbctf/extra/provision.sh -m prod -c certbot -D fbctf.dc4.divo.net.pl -e divo@divo.net.pl -s $PWD