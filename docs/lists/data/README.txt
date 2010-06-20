How to add a new mailing list to http://lists.perl.org/

1) Edit lists.json and add info for the new list.  (Look at other
   entries for more examples.)

{
   "name" : "template-toolkit",
   "summary" : "A mailing list for general information and news about the Perl Template Toolkit.",
   "rssfeed" : "http://nntp.x.perl.org/rss/perl.template.toolkit.rdf",
   "archive" : "http://www.template-toolkit.org/pipermail/templates/",
   "nntp" : null,
   "date_last_confirmed_active" : null,
   "comments" : "",
   "keywords" : "",
   "sub" : "  http://www.template-toolkit.org/mailman/listinfo/templates",
   "unsub" : "  http://www.template-toolkit.org/mailman/listinfo/templates",
   "help" : null,
   "url" : "http://www.template-toolkit.org/",
   "defunct" : "0",
   "module" : "Template-toolkit"
}

2) Validate

Please use validate.pl to make sure your JSON parses correctly (requires JSON from CPAN). The -d flag dumps out a properly formatted file.

Here's a suggested workflow:

cp lists.json lists.json.orig
edit lists.json
validate.pl -d lists.json > lists.json.new
diff -u lists.json lists.json.new

if there are any diffs, edit lists.json and repeat.
