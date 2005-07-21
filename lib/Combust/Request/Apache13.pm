package Combust::Request::Apache13;
use strict;
use base qw(Combust::Request);
use Apache::Request;
use Apache::Cookie;

sub _r {
  my $self = shift;
  return $self->{_r} if $self->{_r};
  return $self->{_r} = Apache::Request->instance;
}

sub req_param {
  shift->_r->param(@_);
}

sub notes {
  shift->_r->pnotes(@_);
}

sub hostname {
  shift->_r->hostname;
}

sub get_cookie {
  my $c = shift->_r->cookie(shift);
  $c ? $c->value : undef;
}

sub set_cookie {
  my ($self, $name, $value, $args) = @_;

  my $cookie = Apache::Cookie->new(
				   $self->{r},
				   -name	=> $name,
				   -value	=> $value,
				   -domain	=> $args->{domain},
				   ($args->{expires} 
				    ? (-expires => $args->{expires}) 
				    : ()
				   ),
				   -path	=> $args->{path},
				  );

  push @{$self->{cookies_out}}, $cookie;
}

sub bake_cookies {
  my $self = shift;
  $_->bake for @{$self->{cookies_out}};
}

1;
