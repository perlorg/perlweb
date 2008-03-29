package Combust::Control::Mason;
use strict;
use base qw(Combust::Control);

#
# TODO: make a reasonable default mason_handler.  Maybe with the same document path as TT uses?  Hmn.
#

#  my $ah = new HTML::Mason::ApacheHandler
#  (comp_root=> [[$site => "/home/combust/htdocs/$site"],
#                  [common => "/home/combust/htdocs/shared"]],
#    data_dir => "/home/combust/mason/data-$site",
#    error_mode => "output",
#    error_format => 'html',
#   );

# sub mason_handler {
#   $ah;
# }

my $root = $ENV{CBROOTLOCAL};

sub render {
  my $self = shift;

  return 404 if $self->r->filename =~ m/\/_[^\/]+$/;  

  my $site = $self->r->dir_config('site');
  $self->r->notes('site', $site);

  # mason documents are always dynamic, so say last-modified "now"
  $self->r->update_mtime(time);

  my $out;

  my $ah = HTML::Mason::ApacheHandler->new
    (comp_root=> [[$site => "$root/htdocs/$site"],
                  [common => "$root/htdocs/shared"]],
     data_dir => "$root/mason/data-$site",
     error_mode => "output",
     error_format => 'html',
     out_method   => sub { $out .= join "", grep { defined $_ } @_ },
     auto_send_headers => 0, 
    );
  
  my $status;

  eval {
    $status = $ah->handle_request($self->r);
  };
  warn $@ if $@;

  # Do something sensible on server errors

  return $status, $out;

}


1;
