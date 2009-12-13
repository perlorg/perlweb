How to add a new mailing list to http://lists.perl.org/

1) Create JSON data/lists/<name>.json e.g.:

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

2) Create list/<name>.html

[%- PROCESS tpl/maillist_page.html list => 'activeperl' -%]

3) Add to category config, edit...

data/categories.html
