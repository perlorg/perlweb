#!/bin/sh
echo Content-Type: text/plain
echo
echo
echo Running SVN update
echo

cd $CBROOT/docs
/usr/local/bin/svn update
