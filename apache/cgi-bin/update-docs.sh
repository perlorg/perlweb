#!/bin/sh
echo Content-Type: text/plain
echo
echo


if [ -z $CBROOT ]
then
  echo No CBROOT specified.  Defaulting to /home/newweb
  echo
  CBROOT=/home/newweb
fi


echo Running SVN update - $CBROOT
echo

# update these branches
AUTO_UPDATE="live"

for branch in $AUTO_UPDATE
do
  cd $CBROOT/docs/$branch
  /usr/local/bin/svn update
done
