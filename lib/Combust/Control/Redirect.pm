package Combust::Control::Redirect;
use strict;
use base 'Combust::Control';

# this should really be more extensible and dispatch to subclasses
# instead of hardcoding things here.

my %bookstores =
  ( 'amazon' => 'http://www.amazon.com/exec/obidos/ASIN/#ISBN#/develooper',
    'amazonuk' => 'http://www.amazon.co.uk/exec/obidos/ASIN/#ISBN#/develooper-21',
    'fatbrain' => 'http://www1.fatbrain.com/asp/bookinfo/bookinfo.asp?theisbn=#ISBN#&from=VFK102',
    'bn' => 'http://service.bfast.com/bfast/click?bfmid=2181&sourceid=38537477&bfpid=#ISBN#&bfmtype=book',
    'powells' => 'http://www.powells.com/cgi-bin/partner?partner_id=25774&cgi=search/search&searchtype=isbn&searchfor=#ISBN#'
  );

my %sites =
  ( ticketmaster => "http://www.ticketmaster.com/",
    citysearch   => "http://www.citysearch.com/",
    # ...
  );

sub find_url {
  my ($r) = @_;
  if ($r->param('type') eq "book") {
    die "Invalid ISBN" unless $r->param('isbn') =~ /^[A-Z0-9]+$/;
    my $shop = $r->param('shop');
    die "Unknown Bookstore: $shop"
      unless exists $bookstores{ $shop };
    my $url = $bookstores{ $shop };
    $url =~ s/\#ISBN\#/$r->param('isbn')/e;
    return $url;
  }
  elsif ($r->param('type') eq "site") {
    # can't use straight URLs, because they let us become an open
    # bouncepoint for things.  So.. we've got to code sites.
    # Eventually this should be in a .ht file or something.
    die "Uniknown Site"
      unless exists $sites{ $r->param('id') };
    return $sites{ $r->param('id') };
  }
  return "";
}


sub handler ($$) {
  my ($class, $r) = @_;

  $r = Apache::Request->instance($r);
  my $url;

  eval { $url = find_url($r) };
  $r->pnotes(error => "$@") if $@;
  die $@ if $@;
  if ($url) {
    $r->status(302);
    $r->header_out("Location",$url);
    my $output = qq[
    You will be redirected to <A HREF="$url">$url</A> now.
		   ];
    $class->send_output($r,\$output);
  } else {
    # If we can't handle it, pass it to CC::Error, which will default
    # to a 404.
    return Combust::Control::Error->handler($r);
  }

}

1;
