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
    'powells' => 'http://www.powells.com/cgi-bin/partner?partner_id=25774&cgi=search/search&searchtype=isbn&searchfor=#ISBN#',
    'bookpool' => 'http://www.bookpool.com/.x/SSSSSS_C200/sm/#ISBN#',
  );

my %sites =
  ( ticketmaster => "http://www.ticketmaster.com/",
    citysearch   => "http://www.citysearch.com/",
    # ...
  );

sub find_url {
  my $self = shift;

  my $type = $self->req_param('type') || $self->req_param('url');


  if ($type eq "book") {
    my $isbn = $self->req_param('isbn') || $self->req_param('bookisbn');
    die "Invalid ISBN" unless $isbn =~ /^[A-Z0-9]+$/;
    my $shop = $self->req_param('shop') || $self->req_param('bookstore');
    die "Unknown Bookstore: $shop"
     unless exists $bookstores{ $shop };
    my $url = $bookstores{ $shop };
    $url =~ s/\#ISBN\#/$isbn/e;
    return $url;
  }
  elsif ($self->req_param('type') eq "site") {
    # can't use straight URLs, because they let us become an open
    # bouncepoint for things.  So.. we've got to code sites.
    # Eventually this should be in a .ht file or something.
    die "Uniknown Site"
      unless exists $sites{ $self->req_param('id') };
    return $sites{ $self->req_param('id') };
  }
  return "";
}


sub render ($$) {
  my ($self) = @_;

  my $url;
  eval { $url = $self->find_url() };
  $self->notes(error => "$@") if $@;
  die $@ if $@;
  if ($url) {
    return $self->redirect($url);
  }
  else {
    # If we can't handle it, pass it to CC::Error, which will default
    # to a 404.
    return 404;
    # return $self->Combust::Control::Error::render();
  }

}

1;
