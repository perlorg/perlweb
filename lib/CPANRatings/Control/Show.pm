package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use CPANRatings::Model::SearchCPAN qw();
use Apache::Constants qw(OK NOT_FOUND);

sub render {
  my $self = shift;

  my $r = $self->r;

  my ($mode, $id, $format) = ($r->uri =~ m!^/([ad]|user|dist)/([^/]+?)(?:\.(html|rss))?$!);
  return 404 unless $mode and $id;

  $format = $self->req_param('format') || $format || 'html';
  $format = 'html' unless $format eq "rss";

  if ($mode eq 'a') {
    my $user = CPANRatings::Model::User->retrieve($id) or return NOT_FOUND;
    return $self->redirect("/user/" . $user->username . ($format ne "html" ? ".$format" : ''));
  }
  elsif ($mode eq 'd') {
    return $self->redirect("/dist/$id" . ($format ne "html" ? ".$format" : ''));
  }

  $mode = "distribution" if $mode eq "dist";

  my $user;
  if ($mode eq 'user') {
    ($user) = CPANRatings::Model::User->search(username => $id) or return NOT_FOUND;
    $id = $user->id;
  }

  my $template = 'display/list.html';

  $self->tpl_param('mode' => $mode);
  $self->tpl_param('header' => "$id reviews" ) if $mode eq "distribution";

  if ($mode eq "user") {
    $self->tpl_param('header' => "Reviews by " . $user->name);
  }
  else {
    unless (CPANRatings::Model::SearchCPAN->valid_distribution($id)) {
      return NOT_FOUND;
    }
    my ($first_review) = CPANRatings::Model::Reviews->search(distribution => $id);
    $self->tpl_param('distribution' => $first_review->distribution) if $first_review;
    $self->tpl_param('distribution' => $id) unless $first_review;
  }

  my $reviews = CPANRatings::Model::Reviews->search(
						    ($mode eq "user" ? "user_id" : $mode)
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
