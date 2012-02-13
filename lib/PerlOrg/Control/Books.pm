package PerlOrg::Control::Books;
use strict;
use base 'PerlOrg::Control';

my %bookstores =
  ( 'amazon' => 'http://www.amazon.com/exec/obidos/ASIN/#ISBN#/develooper',
    'amazonuk' => 'http://www.amazon.co.uk/exec/obidos/ASIN/#ISBN#/develooper-21',
    'powells' => 'http://www.powells.com/partner/25774/biblio/#ISBN#',
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
    die "Unknown Site"
      unless exists $sites{ $self->req_param('id') };
    return $sites{ $self->req_param('id') };
  }
  return "";
}


sub render {
  my $ self = shift;

  my $url;
  eval { $url = $self->find_url() };
  if (my $err = $@) {
      warn "find_url error: $err";
  }
  if ($url) {
    return $self->redirect($url);
  }
  else {
    return 404;
  }

}

1;
