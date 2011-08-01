package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);

sub render {
  my $self = shift;

  if ($self->request->uri =~ m!^/(index\.html)?$!) {
      $self->tpl_param('reviews', scalar $self->schema->review->recent );
  }

  $self->SUPER::render(@_);
}


1;
