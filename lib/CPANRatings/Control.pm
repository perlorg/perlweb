package CPANRatings::Control;
use Combust::Control;
@ISA = qw(Combust::Control);
use strict;
use Apache::Cookie;
use LWP::Simple qw(get);
use Combust::Cache;
use Apache::Util qw();
use CPANRatings::Model::Reviews;

sub super ($$) {
 
  my $self = shift->SUPER::_init(@_);

  $self->param('user_info', $self->user_info);

  $self->SUPER::super(@_);
}

sub is_logged_in {
  my $self = shift;
  my $user_info = $self->user_info;
  return 1 if $user_info and $user_info->{user_id};
  return 0;
}

sub user_info {
  my $self = shift;
  my $cookies = Apache::Cookie->new($self->{r})->parse || {};
  return {} unless $cookies->{ducttape};
  my $cookie = $cookies->{ducttape}->value;

  my $cache = Combust::Cache->new( type => 'auth' );

  my $data = $cache->fetch(id => "ducttape=$cookie");
  return $data->{data} if $data;

  warn "has ducttape cookie: ", $cookie;
  $cookie =~ s/[^a-z0-9]//g;
  $data = get("http://auth.perl.org/dbgw/cookie_validate?sid=$cookie");
  warn "Data: $data";
  return {} unless $data =~ s/^OK\n//s;
  my $user_data = +{ map { split /\t/ } split /\n/, $data };
  #warn Data::Dumper->Dump([\$user_data, \@x], [qw(user_data x)]);

  $cache->store(data => $user_data, expires => 5*60 );

  $user_data;
}

sub login {
  my $self = shift;
  my $r = $self->r;
  return $self->redirect($r,
			 "http://auth.perl.org/login?redirect=http://"
			 . $self->config->site->{cpanratings}->{servername}
			 . $self->r->uri 
			 . ($r->query_string ? Apache::Util::escape_uri("?" . $r->query_string) : '')
			); 
}

1;
