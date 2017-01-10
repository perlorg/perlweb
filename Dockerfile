FROM centos:centos6

# Cache buster for occasionally resetting the cached images for the yum commands
ENV LAST_UPDATED 2017-01-10

ADD docker/mariadb.repo /etc/yum.repos.d/
RUN yum -y install epel-release; yum -y upgrade; \
    yum -y install perl cronolog tar bzip2 gcc patch \
      git openssl-devel expat-devel \
      MariaDB-devel MariaDB-compat MariaDB-client \
      zlib zlib-devel; \
    yum clean all
ENV PERLBREW_ROOT=/perl5
RUN curl -L http://install.perlbrew.pl | bash

ENV PERLBREW_PERL=perl-5.24.0

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH=/perl5/bin:/perl5/perls/${PERLBREW_PERL}/bin:$PATH
ENV PERLBREW_MANPATH=/perl5/perls/${PERLBREW_PERL}/man
ENV PERLBREW_PATH=/perl5/bin:/perl5/perls/${PERLBREW_PERL}/bin

RUN /perl5/bin/perlbrew init
RUN /perl5/bin/perlbrew install -j 4 ${PERLBREW_PERL}; perlbrew clean; rm -fr /perl5/perls/perl-*/man
RUN /perl5/bin/perlbrew install-cpanm
RUN /perl5/bin/perlbrew switch ${PERLBREW_PERL}

ENV PERLBREW_SKIP_INIT=1

#RUN curl -fo /tmp/go.tar.gz https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz && \
#  tar -C /usr/local -xzf /tmp/go.tar.gz; rm /tmp/go.tar.gz
#ENV GOPATH=/go
#ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

ADD .modules /tmp/modules.txt
ADD combust/.modules /tmp/combust-modules.txt

RUN grep -hv '^#' /tmp/combust-modules.txt /tmp/modules.txt | \
  cpanm -n; rm -fr ~/.cpanm; \
  rm -fr /perl5/perls/perl-*/man

ENV CBROOTLOCAL=/perlweb/
ENV CBROOT=/perlweb/combust
ENV CBCONFIG=/perlweb/combust.docker.conf

# optional; in production we load the data into the container
#VOLUME /perlweb

WORKDIR /perlweb
EXPOSE 8235

RUN groupadd perlweb && useradd -g perlweb perlweb
RUN chown perlweb:perlweb /perlweb

ADD docker/container-run.sh /usr/bin/run

USER perlweb
