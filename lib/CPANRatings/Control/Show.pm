package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use CPANRatings::Model::SearchCPAN qw();

sub handler ($$) {
  my ($self, $r) = @_;

  my ($mode, $id, $format) = ($r->uri =~ m!^/([ad])/([^/]+?)(?:\.(html|rss))?$!);
  return 404 unless $mode and $id;

  $mode = "author" if $mode eq "a";
  $mode = "distribution" if $mode eq "d";

  $format = $r->param('format') || $format || 'html';
  $format = 'html' unless $format eq "rss";

  my $template = 'display/list.html';

  $self->param('mode' => $mode);
  $self->param('header' => "$id reviews" ) if $mode eq "distribution";

  if ($mode eq "author") {
    my ($first_review) = CPANRatings::Model::Reviews->search_author($id);
    $self->param('header' => "Reviews by " . $first_review->user_name) if $first_review;
  }
  else {

    unless (CPANRatings::Model::SearchCPAN->valid_distribution($id)) {
      return 404;
    }
    my ($first_review) = CPANRatings::Model::Reviews->search(distribution => $id);
    $self->param('distribution' => $first_review->distribution) if $first_review;
    $self->param('distribution' => $id) unless $first_review;
  }

  my $reviews = CPANRatings::Model::Reviews->search(
						    ($mode eq "author" ? "user_id" : $mode)
						    => $id,
						    { order_by => 'updated desc' }
						   );


  $self->param('reviews' => $reviews); 


  my $output;

  my $content_type = '';

  if ($format eq "html") {
    $content_type = 'text/html';
    $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);
  }
  elsif ($format eq "rss") {
    $output = $self->as_rss($r, $reviews, $mode, $id);
    $content_type = 'application/rdf+rss';
  }

  $self->send_output(\$output, $content_type);
}

1;
