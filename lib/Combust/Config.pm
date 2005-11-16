package Combust::Config;
use strict;
use Config::Simple;
use Data::Dumper qw();
use Sys::Hostname qw(hostname);
use Carp qw(carp croak cluck);

my $file = $ENV{CBCONFIG} || "$ENV{CBROOT}/combust.conf";
$file = "$ENV{CBROOTLOCAL}/combust.conf" if $ENV{CBROOTLOCAL};

my $cfg = new Config::Simple($file) or die Config::Simple->error();

my %Config = $cfg->vars();
#warn Data::Dumper->Dump([\$cfg],[qw(cfg)]);
#warn Data::Dumper->Dump([\%Config],[qw(Config)]);

my %dbs = _setup_dbs();  

sub _setup_dbs {

  croak "Old database configuration detected, you must update the syntax. See combust.conf.sample" 
    if $cfg->param('db_data_source');

  my %sections = map { $_ =~ s/^database-(.*?)\..*/$1/; $_ => 1 } grep { m/^database/ } keys %Config;
  my $got_default = 0;
  foreach my $section (keys %sections) {
    my $db_name = $section; 
    my $db_config  = $cfg->param(-block => "database-$section"); 
    $dbs{default}  = $db_config and $got_default++ if $db_config->{default};
    $dbs{$db_name} = $db_config;
  }

  unless ($got_default) {
    if (scalar (grep { !$dbs{$_}->{alias} } keys %dbs) > 1) {
      croak 'You defined more than one database but didn\'t mark one of them "default=1"';
    }
    else {
      my ($db_name) = grep { !$dbs{$_}->{alias} } keys %dbs;
      $dbs{default} = $dbs{$db_name} if $db_name;
    }
  }

  %dbs;
}  

my $singleton;

sub new {
  return $singleton if $singleton;
  $singleton = shift->_new(@_);
}

sub _new {
  my ($class, %args) = (shift, @_);
  bless( {}, $class);
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

  $self->{_site} = $h; 
}

sub sites_list { 
  my $sites = $cfg->param('sites');
  ref $sites ? @$sites : ($sites);
}

sub sites {
  my $self = shift;
  # grep for non-configured sites?
  +{ map { $_ => $self->site->{$_} } $self->sites_list };
}

sub servername {
  $cfg->param('servername') || hostname || 'combust-server';
}

sub port {
  $cfg->param('port') || 8225;
}

sub external_port {
  # should we default to $self->port instead of undef (and then require port 80 to be 
  # configured when you use a proxy?)
  $cfg->param('external_port') || undef;
}

sub proxyip_forwarders {
  my $allow = $cfg->param('proxyip_forwarders') || "127.0.0.1";
  ref $allow ? @$allow : ($allow);
}

sub base_url {
  my $self = shift;
  my $sitename = shift or carp "sitename parameter required" and return;
  carp "no [$sitename] site configured" and return unless $self->site->{$sitename};
  my $site = $self->site->{$sitename};
  my $servername = $site->{servername};
  my $port = $self->external_port || 80;
  my $protocol = 'http';
  $protocol = 'https' if $port and $port == 443;
  my $base_url = "$protocol://$servername" . 
    ((($protocol eq 'http' and $port == 80) or ($protocol eq 'https' and $port == 443))
      ? ''
      : ":$port");
  return $base_url;
}

sub database {
  my ($self, $db_name) = @_;
  carp "No databases configured in the combust configuration" and return unless %dbs; 

  $db_name ||= 'default';

  $db_name = $self->_resolve_db_alias($db_name);
  
  unless ($db_name and $dbs{$db_name}) {
    cluck "no database $db_name defined, using default" if $db_name;
    $db_name = 'default';
    $db_name = $self->_resolve_db_alias($db_name);
  }
  $dbs{$db_name};
}

sub _resolve_db_alias {
  my ($self, $db_name) = @_;
  if ($dbs{$db_name} and $dbs{$db_name}->{alias}) {
    return $dbs{$db_name}->{alias};
  }
  return $db_name;
}

sub db_data_source { shift->database->{data_source}; }
sub db_password    { shift->database->{password};    }
sub db_user        { shift->database->{user};        }

sub apache_reload {
  # maybe this should have been reversed
  $cfg->param('apache_reload') || 0;
}

sub apache_dumpheaders {
  $cfg->param('apache_dumpheaders') || 0;
}

sub template_timer {
  $cfg->param('template_timer') || 0;
}


# cronolog settings
# {{{

sub use_cronolog {
  $cfg->param('use_cronolog') || 0;
}

sub cronolog_path {
  $cfg->param('cronolog_path') || "/usr/sbin/cronolog";
}

sub cronolog_template {
  $cfg->param('cronolog_template') || "%Y/%m/LOGFILE.%Y%m%d";
}

sub cronolog_params {
  $cfg->param('cronolog_params') || "";
}


# }}}

sub apache_root {
  my $root = $cfg->param('apache_root');
  unless (defined $root) {
    ($root = $_[0]->httpd) =~ s!/s?bin/httpd$!!;
  }
  $root;
}

sub apache_config {
  my $config = $cfg->param('apache_config');
  unless (defined $config) {
    $config = $_[0]->apache_root . '/conf';
  }
  $config;
}

sub httpd {
  $cfg->param('httpd') || '/home/perl/apache1/bin/httpd';
}

#sub config {
#  $cfg;
#}

sub root {
  $ENV{CBROOT};
}

sub root_local {
  $ENV{CBROOTLOCAL} || $ENV{CBROOT};
}

sub root_docs {
  my $self = shift;
  $ENV{CBDOCS} || $cfg->param('docs') || ($self->root_local . "/" . $self->docs_name);
}

sub docs_name {
  $cfg->param('docs_name') || 'docs';
}


1;
