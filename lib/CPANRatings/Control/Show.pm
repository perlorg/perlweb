package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;

sub handler ($$) {
  my ($self, $r) = @_;

  my ($mode, $id) = ($r->uri =~ m!^/([ad])/([^/]+)!); 
  return 404 unless $mode and $id;

  $mode = "author" if $mode eq "a";
  $mode = "distribution" if $mode eq "d";

  my $template = 'display/list.html';


  my $reviews = CPANRatings::Model::Reviews->search(
						    ($mode eq "author" ? "user_id" : $mode)
						    => $id
						   );

  $self->param('mode' => $mode);

  $self->param('reviews' => $reviews); 

  $self->param('header' => "$id reviews" ) if $mode eq "distribution";

  if ($mode eq "author") {
    my ($first_review) = CPANRatings::Model::Reviews->search_author($id);
    $self->param('header' => "Reviews by " . $first_review->user_name) if $first_review;
  }
  else {
    my ($first_review) = CPANRatings::Model::Reviews->search(distribution => $id);
    $self->param('distribution' => $first_review->distribution) if $first_review;
  }

  my $output;
  $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);

  $self->send_output($r, \$output);
}

1;
