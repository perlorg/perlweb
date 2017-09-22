#!/bin/sh
set -ex

ls -la /git/
ls -la /git/perlweb/

rmdir /perlweb
ln -s /git/perlweb /perlweb

ls -la /
ls -la /perlweb

ls -la /perlweb/bin /perlweb/combust/bin

cd /perlweb

# download RSS files etc on restarts
./bin/cron_hourly &

./combust/bin/httpd
