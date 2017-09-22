FROM quay.io/ntppool/base-os:v2.2

# Cache buster for occasionally resetting the cached images for the yum commands
ENV LAST_UPDATED 2017-05-30

USER root

RUN apk update; apk upgrade ; apk add curl git \
  perl-dev wget make \
  expat-dev zlib-dev libressl-dev libressl \
  mariadb-client mariadb-client-libs mariadb-dev build-base

ADD .modules /tmp/modules.txt
ADD combust/.modules /tmp/combust-modules.txt

RUN curl -sfLo /usr/bin/cpanm https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm; chmod a+x /usr/bin/cpanm

RUN grep -hv '^#' /tmp/combust-modules.txt /tmp/modules.txt | \
  cpanm -n; rm -fr ~/.cpanm; rm -f /tmp/modules /tmp/combust-modules.txt

ENV CBROOTLOCAL=/perlweb/
ENV CBROOT=/perlweb/combust
ENV CBCONFIG=/perlweb/combust.docker.conf

# optional; in production we load the data into the container
#VOLUME /perlweb

WORKDIR /perlweb
EXPOSE 8235

RUN addgroup perlweb && adduser -D -G perlweb perlweb
RUN chown perlweb:perlweb /perlweb

ADD docker/container-run.sh /usr/bin/run

USER perlweb

CMD /usr/bin/run
