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


sub handler {
  my $self = shift;

  my $ah = $self->mason_handler;

  return 404 if $self->r->filename =~ m/\/_[^\/]+$/;  

  my $status;

  eval {
    $status = $ah->handle_request($self->r);
  };
  warn $@ if $@;

  # Do something sensible on server errors

}


1;
