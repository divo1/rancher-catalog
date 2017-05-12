FROM ubuntu:trusty
LABEL maintainer="Boik Su <boik@tdohacker.org>"

ENV HOME /root/fbctf

ARG MODE=dev
ARG TYPE=self

WORKDIR $HOME
#COPY . $HOME

RUN apt-get update \
  && apt-get install -y \
  rsync \
  git \
  curl \
  ca-certificates
RUN git clone https://github.com/facebook/fbctf $HOME
RUN chown www-data:www-data $HOME \
  && ./extra/provision.sh -m $MODE -c $TYPE -s `pwd` --docker \
  && rm -f /var/run/hhvm/sock \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CMD ["/root/fbctf/extra/service_startup.sh"]