package CPANRatings::Control::Logout;
use base qw(CPANRatings::Control);
use strict;

sub render {
  my $self = shift;
  $self->logout;
}


1;
