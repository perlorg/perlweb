package Combust::Config;
use strict;
use Config::Simple;
use Data::Dumper qw();
use Sys::Hostname qw(hostname);

my $file = "$ENV{CBROOT}/combust.conf";

#my %Config;
#Config::Simple->import_from($file, \%Config);

my $cfg = new Config::Simple($file)  or die Config::Simple->error();

my %Config = $cfg->vars();
#warn Data::Dumper->Dump([\$cfg],[qw(Config)]);
#warn Data::Dumper->Dump([\%Config],[qw(Config)]);

my $singleton;

sub new {
  return $singleton if $singleton;
  $singleton = shift->_new(@_);
}

sub _new {
  my ($proto, %args) = (shift, @_);
  my $class = ref $proto || $proto;
  my $type  = $args{type}|| '';
  my $self = { };
  $self = bless( $self, $class);
}

sub site {
  my $self = shift;
  return $self->{_site} if $self->{_site};
  my $h = {};

  for my $site ($self->sites_list) {
    my $sd = $cfg->param(-block=>$site);
    # FIXME: should resolve refs and stuff ...
    $h->{$site} = $sd;
  }

  warn Data::Dumper->Dump([\$h], [qw(x)]);

  $self->{_site} = $h; 
}

sub sites_list { 
  my $sites = $cfg->param('sites');
  ref $sites ? @$sites : ($sites);
}

sub sites {
  #warn Data::Dumper->Dump([\$sites], [qw(sites)]);
  +{ map { $_ => 1 } shift->sites_list };
}

sub servername {
  $cfg->param('servername') || hostname || 'combust-server';
}

sub port {
  $cfg->param('port') || 8225;
}

#sub config {
#  $cfg;
#}

1;
