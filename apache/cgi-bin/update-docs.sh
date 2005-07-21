#!/bin/sh
echo Content-Type: text/plain
echo
echo


if [ -z $CBROOT ]
then
  echo No CBROOT specified.  
  echo
  exit
fi


echo Running SVN update - $CBROOT
echo

# update these branches
AUTO_UPDATE="live"

for branch in $AUTO_UPDATE
do
  cd $CBROOT/docs/$branch && /usr/local/bin/svn update
done

if [ -d $CBROOT/planets/ ]
then
  cd $CBROOT/planets/sites/ && /usr/local/bin/svn update
fi
