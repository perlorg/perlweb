package Combust::Request::CGI;
use strict;
use base qw(Combust::Request);
use CGI;

sub _r {
  my $self = shift;
  return $self->{_r} if $self->{_r};
  return $self->{_r} = CGI->new;
}

sub req_param {
  shift->_r->param(@_);
}

sub hostname {
  $ENV{SERVER_NAME};
}

sub get_cookie {
  shift->_r->cookie(shift);
}

sub set_cookie {
  my ($self, $name, $value, $args) = @_;

  my $cookie = $self->_r->cookie(-name	=> $name,
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
  print $self->_r->header(-cookike => $_)
    for @{$self->{cookies_out}};
  1;
}

sub import_constants {
    my $caller = caller();
    eval "package $caller; use constant OK => 200; use constant NOT_FOUND => 404;";
    $@ and warn "trouble importing constants into $caller: $@" and return 0;
    return 1;
}


1;
