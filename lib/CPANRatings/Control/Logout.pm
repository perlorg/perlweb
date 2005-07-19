package CPANRatings::Control::Logout;
use base qw(CPANRatings::Control);
use strict;

sub render {
  my $self = shift;
  my $return_url = $self->config->base_url('cpanratings');
  $self->cookie($CPANRatings::Control::cookie_name, 0);
  return $self->redirect($self->bitcard->logout_url(r => $return_url));
}


1;
