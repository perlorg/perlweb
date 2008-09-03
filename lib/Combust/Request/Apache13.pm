package Combust::Request::Apache13;
use strict;
use base qw(Combust::Request);
use Apache::Request;
use Apache::Cookie;
use Apache::File;
use Combust::Config;

my $config = Combust::Config->new;


sub _r {
  my $self = shift;
  return $self->{_r} if $self->{_r};
  return $self->{_r} = Apache::Request->instance(Apache->request,
                                                 TEMP_DIR => $config->work_path,
                                                 );
}

sub req_param {
  shift->_r->param(@_);
}

sub req_params {
  shift->_r->parms;
}

sub notes {
  shift->_r->pnotes(@_);
}

sub upload {
  shift->_r->upload(@_);
}

sub hostname {
  shift->_r->hostname;
}

sub header_in {
    shift->_r->header_in(@_);
}

sub header_out {
    shift->_r->header_out(@_);
}

sub remote_ip {
    shift->_r->connection->remote_ip;
}

sub uri {
  shift->_r->uri(@_);
}

sub get_args {
  shift->_r->args;
}

sub request_url {
  my $self = shift;
  return 'http://'.$self->_r->hostname.$self->uri.($self->get_args ? '?' . $self->get_args : '');
}

sub method {
  lc shift->_r->method; 
}

sub update_mtime {
  shift->_r->update_mtime(shift);
}

sub send_http_header {
    shift->_r->send_http_header(@_);
}

sub sendfile {
    my ($self, $file) = @_;
    open my $fh, "<", $file or die "$!";
    my $rv = $self->_r->send_fh($fh);
    close $fh;
    return $rv;
}

sub get_cookie {
  my ($self, $name) = @_;
  unless ($self->{cookies}) {
    $self->{cookies} = Apache::Cookie->fetch || {}; 
  }
  my $c = $self->{cookies}->{$name};
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
