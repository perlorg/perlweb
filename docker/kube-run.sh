#!/bin/sh
set -ex

cd /git/perlweb

SU=""
if [ "`id -u`" -eq 0 ]; then
  SU="su-exec perlweb"
fi

# download RSS files etc on restarts
$SU ./bin/cron_hourly &

$SU ./combust/bin/httpd
