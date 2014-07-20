#!/bin/bash

# Config file format is one hostper line
CONFIG_FILE=~/etc/perlweb_hosts.cfg

if [[ ! -e ${CONFIG_FILE} ]]; then
    echo "ERROR: ${CONFIG_FILE} does not exist" >/dev/stderr
    exit 1;
fi

PERLWEB_HOSTS="$(cat ${CONFIG_FILE} | xargs)"

echo 
echo "Perlweb Hosts: $PERLWEB_HOSTS"
echo "Pushing live in 10 seconds..."
echo "  hit Ctrl-C if you haven't verified the content yet."
sleep 10
for h in ${PERLWEB_HOSTS}; do
    echo "Updating ${h} ..."
    if host ${h} >/dev/null 2>/dev/null; then
      ssh -x -A perlweb@${h} '(cd ~/perlweb ; git pull --rebase ; git submodule update )'; 
    else
      echo "ERROR: host ${h} not found.  Skipping" >/dev/stderr
    fi
done
