# perlweb development

Code for various perl.org sites hosted in the main perl.org infrastructure.

N.b Development requires docker to make things simple..

## Setup

```sh
   git clone git://github.com/perlorg/perlweb.git
   cd perlweb
   git submodule update --init
```

## Developing:

### Edit your local /etc/hosts file, add:
```
127.0.0.1  wwwperl.local
127.0.0.1  qaperl.local
127.0.0.1  nocperl.local
127.0.0.1  devperl.local
127.0.0.1  dbiperl.local
127.0.0.1  perl4libperl.local
127.0.0.1  debuggerperl.local
127.0.0.1  learnperl.local
127.0.0.1  listsperl.local
```

### Container: build and run

```sh
docker build --tag perlweb-dev .
docker run -it -p 8235:8235 -v $(pwd):/git/perlweb perlweb-dev  /bin/bash
cd /git/perlweb
./combust/bin/httpd
```

You should now be able to access http://wwwperl.local:8235/

### CSS/JS: rebuilding
(On your _host_, not in the docker container)

```
npx grunt
```

(You can use `npx grunt watch` for it to auto build when you make changes)




## Misc

### Static header config

Static headers can be configured in combust.conf, either globally or
per-site.

```
[headers-global]
X-Frame-Options = deny

[headers-www]
X-Frame-Options = sameorigin
```


### Copyright

`perlweb` is Copyright 2003-2012 Ask Bjørn Hansen.  See the LICENSE file.
