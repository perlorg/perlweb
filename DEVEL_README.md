# Doing simple local web development

### Setup your config
Edit `combust.devel.conf` (if needed)

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

### Get this repo and init submodules
```sh
   git clone git://github.com/perlorg/perlweb.git
   cd perlweb
   git submodule update --init
```

### Build development image
```sh
docker build --tag perlweb-dev -f Devel.Dockerfile .
```

### Run development container and connect
```
docker run -it -p 8230:8230 -v `pwd`:/git/perlweb perlweb-dev  /bin/sh
```


### Start service
```
cd /git/perlweb
./combust/bin/httpd
```

### Connect

http://wwwperl.local:8230/
http://qaperl.local:8230/
..