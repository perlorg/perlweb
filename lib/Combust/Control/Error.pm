package Combust::Control::Error;
use strict;
use Combust::Constant qw(OK);
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

  my $r_err = $r->main || $r->prev || $r;
  # the default template uses error_uri, but error_url was setup here too...
  $self->tpl_param('error_url' => $r_err->uri);
  $self->tpl_param('error_uri' => $r_err->uri);

  return OK, $self->evaluate_template($template);
}

1;
