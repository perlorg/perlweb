#!/bin/sh
set -ex

cd /perlweb

GOSU=""
if [ "`id -u`" -eq 0 ]; then
  GOSU="gosu perlweb"
fi

# download RSS files etc on restarts
$GOSU ./bin/cron_hourly &

$GOSU ./combust/bin/httpd
