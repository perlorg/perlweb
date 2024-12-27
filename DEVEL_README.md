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

### Run development container, connect and start service
```
docker run -it -p 8235:8235 -v $(pwd):/git/perlweb perlweb-dev  /bin/sh
cd /git/perlweb
./combust/bin/httpd
```

### View in browse

http://wwwperl.local:8235/
http://qaperl.local:8235/
..

## Updating CSS/JS

On host, not in container...
```sh
npm install
npx grunt
```
(You can use `npx grunt watch` for it to auto build when you make changes)