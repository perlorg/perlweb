package Combust::Control::Error;
use strict;
use base 'Combust::Control';

sub handler ($$) {
  my ($self, $r) = @_;

  $r->uri =~ m!^/error/(\d+)!;
  my $error = $1 || 404;

  my $template = "error/error.html";

  my $error_header = "";
  $error_header = 'File not found' if $error == 404;
  $error_header = 'Server Error'   if $error == 500;

  my $error_text = $r->pnotes('error') || '';

  $self->param('error'        => $error);
  $self->param('error_header' => $error_header);
  $self->param('error_text'   => $error_text);

  # is this right?  
  my $r_err = $r->main || $r->prev || $r;
  $self->param('error_url', $r_err->uri);

  warn "self: $self / ref class: ", ref $self;

  $self->send_output(scalar $self->evaluate_template($template));
}

1;
