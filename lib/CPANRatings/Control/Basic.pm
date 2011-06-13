package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);
use CPANRatings::Model::Reviews;

sub render {
  my $self = shift;

  if ($self->request->uri =~ m!^/(index\.html)?$!) {
      $self->tpl_param('reviews', scalar CPANRatings::Model::Reviews->search_recent );
  }

  $self->SUPER::render(@_);
}


1;
