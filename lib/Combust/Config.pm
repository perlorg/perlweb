package Combust::Config;
use strict;
use Config::Simple;
use Data::Dumper qw();
use Sys::Hostname qw(hostname);

my $file = "$ENV{CBROOT}/combust.conf";
$file = "$ENV{CBROOTLOCAL}/combust.conf" if $ENV{CBROOTLOCAL};

my $cfg = new Config::Simple($file) or die Config::Simple->error();

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

sub db_data_source {
  $cfg->param('db_data_source') || 'db_data_source not configured';
}

sub db_password {
  $cfg->param('db_password') || undef;
}

sub db_user {
  $cfg->param('db_user') || 'combust';
}

sub apache_reload {
  # maybe this should have been reversed
  $cfg->param('apache_reload') || 0;
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
