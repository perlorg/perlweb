#!/bin/sh

# store the checkbot script here temporarily
#   http://degraaff.org/checkbot/

# this program looks good too:
#   http://freshmeat.net/projects/linkchecker/

./checkbot --style http://one.develooper.com/~ask/tmp/checkbot.css  \
   --file /home/ask/public_html/tmp/checkbot.html \
   --ignore http://www.ticketmaster.com/ \
   --url http://new.x.perl.org/

