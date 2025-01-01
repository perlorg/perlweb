FROM harbor.ntppool.org/perlorg/base-os:3.21.0

# Note that this only builds dependencies and such, it doesn't
# actually include the site code etc itself. The site code
# includes the documents which are updated more often and we
# don't want to rebuild and restart the container each time.

USER root

RUN apk update; apk upgrade ; apk add curl git \
  perl-dev wget make \
  expat-dev zlib-dev \
  mariadb-client mariadb-dev build-base

ADD .modules /tmp/modules.txt
ADD combust/.modules /tmp/combust-modules.txt

RUN curl -sfLo /usr/bin/cpanm https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm; chmod a+x /usr/bin/cpanm

RUN grep -hv '^#' /tmp/combust-modules.txt /tmp/modules.txt | \
  cpanm -n; rm -fr ~/.cpanm; rm -f /tmp/modules /tmp/combust-modules.txt

ENV CBROOTLOCAL=/git/perlweb/
ENV CBROOT=/git/perlweb/combust
ENV CBCONFIG=/git/perlweb/combust.docker.conf

# optional; in production we load the data into the container
#VOLUME /perlweb

WORKDIR /
EXPOSE 8235

RUN addgroup perlweb && adduser -D -G perlweb perlweb

RUN mkdir /var/tmp/perlweb; chown perlweb:perlweb /var/tmp/perlweb; chmod 700 /var/tmp/perlweb
RUN ln -s /git/perlweb /perlweb

ADD docker/container-run.sh /usr/bin/run
ADD docker/kube-start /usr/bin/kube-start

USER perlweb

CMD /usr/bin/run
