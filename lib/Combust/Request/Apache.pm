package Combust::Request::Apache;
use strict;
use base qw(Combust::Request);

sub remote_ip {
    shift->_r->connection->remote_ip;
}

sub uri {
  shift->_r->uri(@_);
}

sub args {
  shift->_r->args;
}

sub request_url {
  my $self = shift;
  return 'http://'.$self->_r->hostname.$self->uri.($self->args ? '?' . $self->args : '');
}



1;
