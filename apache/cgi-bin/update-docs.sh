#!/bin/sh
echo Content-Type: text/html
echo
echo
echo Running SVN update
echo

cd ~newweb/docs
/usr/local/bin/svn update
