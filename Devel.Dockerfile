FROM harbor.ntppool.org/perlorg/base-os:3.21.0

# Note that this only builds dependencies and such, it doesn't
# actually include the site code etc itself as you will
# mount that as a volume so you can edit locally

USER root

RUN apk update; apk upgrade ; apk add curl git \
  perl-dev wget make \
  expat-dev zlib-dev \
  mariadb-client mariadb-dev build-base

ADD combust/.modules /tmp/combust-modules.txt
ADD .modules /tmp/modules.txt

RUN curl -sfLo /usr/bin/cpanm https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm; chmod a+x /usr/bin/cpanm

RUN grep -hv '^#' /tmp/combust-modules.txt /tmp/modules.txt | \
  cpanm -n; rm -fr ~/.cpanm; rm -f /tmp/modules /tmp/combust-modules.txt

WORKDIR /
EXPOSE 8235

RUN addgroup perlweb && adduser -D -G perlweb perlweb

RUN mkdir /var/tmp/perlweb; chown perlweb:perlweb /var/tmp/perlweb; chmod 700 /var/tmp/perlweb

ENV CBROOTLOCAL=/git/perlweb/
ENV CBROOT=/git/perlweb/combust
ENV CBCONFIG=/git/perlweb/combust.devel.conf
