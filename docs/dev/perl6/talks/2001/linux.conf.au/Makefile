###########################################
## Makefile
##
##   Standard DocBook -> HTML (via DSSSL)
##
## $Id$
##
## 12/15/00 - Adam Turoff; Created
##
###########################################

################
# Local Config #
################
DOC=perl6-paper
FILES=$(DOC).sgml

###################
# Standard params #
###################
HTML_DSSSL=html.dsl
jade=jade

##################
# Standard rules #
##################
all: html split

html:$(DOC).html
split:$(DOC)/index.html

tarball:$(DOC).tgz

$(DOC).tgz:split
	tar cvfz $(DOC).tgz $(DOC)

clean:
	rm -Rf $(DOC).html $(DOC)

%.html: %.sgml $(HTML_XSLT) $(FILES) $(ENT)
	$(jade) -V nochunks -t sgml -d $(HTML_DSSSL) $<  > $@

%/index.html: %.sgml $(HTML_DSSSL) $(FILES) $(ENT)
	-( [ ! -d $* ] && mkdir $*)
	(cd $* && $(jade) -t sgml -d ../$(HTML_DSSSL) ../$<)
