#!/bin/sh
set -ex

# we have to start the image as root just to make
# this possible. An alternative would be to make it
# into the image and use /git/perlweb when running
# the image just under docker for testing ...
rmdir /perlweb
ln -s /git/perlweb /perlweb

cd /perlweb

# download RSS files etc on restarts
gosu perlweb ./bin/cron_hourly &

gosu perlweb ./combust/bin/httpd
