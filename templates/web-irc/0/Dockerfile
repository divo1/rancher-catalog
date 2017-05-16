FROM alpine:3.5
LABEL maintainer="Mateusz Górny <divo@divo.net.pl>"

WORKDIR /var/www

RUN apk update
RUN apk add --update nodejs
RUN npm install -g thelounge
CMD lounge start