package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);
use CPANRatings::Model::Reviews;

sub handler {
  my ($self, $r) = (shift, shift);

  $self->param('reviews' => CPANRatings::Model::Reviews->new()); 

  $self->SUPER::handler($r, @_);
}


1;
