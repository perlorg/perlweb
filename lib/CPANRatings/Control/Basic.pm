package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);
use CPANRatings::Model::Reviews;

sub handler {
  my ($self, $r) = (shift, shift);

  $self->param('reviews' => CPANRatings::Model::Reviews->new()); 
  if ($r->uri =~ /index\.rss$/) {
    my $reviews = $self->param('reviews')->search_recent;
    my $output = $self->as_rss($r, $reviews);
    $self->send_output(\$output, 'application/rdf+rss');
  } else {
    $self->SUPER::handler($r, @_);
  }
}


1;
