package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);
use CPANRatings::Model::Reviews;

sub render {
  my $self = shift;

  $self->tpl_param('reviews' => CPANRatings::Model::Reviews->new());

  if ($self->r->uri =~ /index\.rss$/) {
    my $reviews = $self->tpl_param('reviews')->search_recent;
    my $output = $self->as_rss($reviews);
    $self->send_output(\$output, 'application/rdf+rss');
  }
  else {
    $self->SUPER::render(@_);
  }
}


1;
