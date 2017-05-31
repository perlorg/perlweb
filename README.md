# perlweb

Code for various perl.org sites hosted in the main perl.org infrastructure.

## Clone the source

```sh
   git clone git://github.com/perlorg/perlweb.git
   cd perlweb
   git submodule update --init
```

## Install dependencies

If you have Dist::Zilla and App::cpanminus installed you can just run:

   `((cd combust; dzil listdeps); dzil listdeps) | sort -u | cpanm`

## Configure combust.conf

The application expects a file called `combust.conf` to exist in the
root directory.  You can start with the `combust.conf.sample` file and
then add

```
[cpanratings]
servername = cpanratings.local

[www]
servername = wwwperl.local

```

... etc.  Add wwwperl.local and cpanratings.local to your /etc/hosts
file so they point to 127.0.0.1.

## Database setup

For some sites you also need to configure a (MySQL) database server.
Setup the `[database-combust]` section in the `combust.conf` file and add a section for cpanratings like:

```
[database-cpanratings]
alias = combust
```

Then run:

```sh
   export CBROOTLOCAL=`pwd`
   export CBROOT=$CBROOTLOCAL/combust
   ./combust/bin/database_update combust
   ./combust/bin/database_update cpanratings
```

To setup the database schemas.  When the schemas change, you can run
the `database_update` command again to get updated.

## Static header config

Static headers can be configured in combust.conf, either globally or
per-site.

```
[headers-global]
X-Frame-Options = deny

[headers-www]
X-Frame-Options = sameorigin
```

## Start httpd

```sh
   export CBROOTLOCAL=`pwd`
   export CBROOT=$CBROOTLOCAL/combust
   ./combust/bin/httpd
```

You should now be able to access http://wwwperl.local:8225/


## Copyright

`perlweb` is Copyright 2003-2012 Ask Bjørn Hansen.  See the LICENSE file.
