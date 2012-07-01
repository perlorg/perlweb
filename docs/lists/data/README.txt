----------------------------------------------------------------------
How to ADD a new mailing list to http://lists.perl.org/
----------------------------------------------------------------------

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

cp lists.json lists.json.old
cp lists.json lists.json.new
edit lists.json.new
validate.pl -d lists.json.new > lists.json
diff -u lists.json.old lists.json

if there are any inappropriate diffs, edit lists.json.new and repeat.

----------------------------------------------------------------------
To DELETE a list...
----------------------------------------------------------------------

Just mark the list as "defunct".  (Set the value to 1.)

We are keeping the data for the old lists in the file, as it may come
in handy at some point in the future.
