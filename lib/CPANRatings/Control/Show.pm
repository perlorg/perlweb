package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use CPANRatings::Model::SearchCPAN qw();
use Apache::Constants qw(OK);

sub render {
  my $self = shift;

  my $r = $self->r;

  my ($mode, $id, $format) = ($r->uri =~ m!^/([ad])/([^/]+?)(?:\.(html|rss))?$!);
  return 404 unless $mode and $id;

  $mode = "author" if $mode eq "a";
  $mode = "distribution" if $mode eq "d";

  $format = $self->req_param('format') || $format || 'html';
  $format = 'html' unless $format eq "rss";

  my $template = 'display/list.html';

  $self->tpl_param('mode' => $mode);
  $self->tpl_param('header' => "$id reviews" ) if $mode eq "distribution";

  if ($mode eq "author") {
    my ($first_review) = CPANRatings::Model::Reviews->search_author($id);
    $self->tpl_param('header' => "Reviews by " . $first_review->user_name) if $first_review;
  }
  else {

    unless (CPANRatings::Model::SearchCPAN->valid_distribution($id)) {
      return 404;
    }
    my ($first_review) = CPANRatings::Model::Reviews->search(distribution => $id);
    $self->tpl_param('distribution' => $first_review->distribution) if $first_review;
    $self->tpl_param('distribution' => $id) unless $first_review;
  }

  my $reviews = CPANRatings::Model::Reviews->search(
						    ($mode eq "author" ? "user_id" : $mode)
						    => $id,
						    { order_by => 'updated desc' }
						   );


  $self->tpl_param('reviews' => $reviews); 

  my $output;

  my $content_type = '';

  if ($format eq "html") {
    return OK, $self->evaluate_template($template), 'text/html';
  }
  elsif ($format eq "rss") {
    $output = $self->as_rss($r, $reviews, $mode, $id);
    return OK, $output, 'application/rdf+rss';
  }

  return OK, 'huh? unknown output format', 'text/plain';
}

1;
