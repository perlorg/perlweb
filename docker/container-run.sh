#!/bin/sh

# for running under docker for testing

cd /perlweb
ls -latr
if [ -e .git ]; then
	echo Already has a git checkout
else
	git clone -b master \
            --recursive https://github.com/perlorg/perlweb.git .
	git submodule update
fi

# download RSS files etc on restarts
./bin/cron_hourly &

./combust/bin/httpd
