# perlweb

Sites moved to new perlweb:

- cpanratings
- dbi
- debugger
- dev
- ldap
- learn
- lists
- noc
- perl4lib
- qa
- sdl
- www
- xml

Sites still running on old perlweb:

- svnaccount


## Clone the source

```sh
   git clone git://git.develooper.com/perlweb.git  # or from github
   cd perlweb
   git submodule update --init
   svn co http://svn.perl.org/perl.org/docs/ 
```

The templates and HTML documents are still hosted in Subversion
despite some of the sites being dependent on the docs/ files. Work in
progress to get that sorted!

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


## Start httpd

```sh
   export CBROOTLOCAL=`pwd`
   export CBROOT=$CBROOTLOCAL/combust
   ./combust/bin/httpd
```

You should now be able to access http://wwwperl.local:8225/


## Copyright

`perlweb` is Copyright 2003-2011 Ask Bjørn Hansen.  See the LICENSE file.

