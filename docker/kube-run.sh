#!/bin/sh
set -ex

cd /perlweb

# download RSS files etc on restarts
gosu perlweb ./bin/cron_hourly &

gosu perlweb ./combust/bin/httpd
