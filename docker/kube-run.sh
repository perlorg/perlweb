#!/bin/sh
cd /perlweb

# download RSS files etc on restarts
./bin/cron_hourly &

./combust/bin/httpd
