package Trivial::Control::One;
use strict;
use base 'Combust::Control';

sub handler ($$) {
  my $self = shift;

  $self->tpl_param('now', scalar localtime );
  my $output = $self->evaluate_template('one');
  if ($@) {
    $self->request->pnotes('error', $@);
    return 404 if $@ =~ m/: not found/;
    return 500; 
  }
  $self->send_output($output, 'text/html');
}

1;
