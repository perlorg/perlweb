package Combust::Control::Error;
use strict;
use Apache::Constants qw(OK);
use base 'Combust::Control';

sub render {
  my $self = shift;

  my $r = $self->r;

  $r->uri =~ m!^/error/(\d+)!;
  my $error = $1 || 404;

  my $template = "error/error.html";

  my $error_header = "";
  $error_header = 'File not found' if $error == 404;
  $error_header = 'Server Error'   if $error == 500;

  my $error_text = $r->pnotes('error') || '';

  $self->tpl_param('error'        => $error);
  $self->tpl_param('error_header' => $error_header);
  $self->tpl_param('error_text'   => $error_text);

  # is this right?  
  my $r_err = $r->main || $r->prev || $r;
  $self->tpl_param('error_url', $r_err->uri);

  warn "self: $self / ref class: ", ref $self;

  return OK, $self->evaluate_template($template);
}

1;
