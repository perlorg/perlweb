package Develooper::DB;
use strict;
use DBI;
use Carp;
use Combust::Config;

use Exporter;
use vars qw(@ISA @EXPORT);
@EXPORT = qw(db_open);
@ISA = qw(Exporter);

my $config = Combust::Config->new();

my %dbh = ();

sub read_db_connection_parameters {

  # my $db = shift || 'combust';

  # my $db = 'combust';
  # $db   .= '_test' if $ENV{TESTMODE};
  # return ("dbi:mysql:database=$db;host=localhost;user=combust;;mysql_read_default_file=$ENV{CBROOT}/.my.cnf");

  my $data_source = $config->db_data_source;
  my ($host) = ($data_source =~ m/host=([^;]+)/);

  return ($host, $data_source, $config->db_user, $config->db_password);


}

sub db_open {
  my ($db, $attr) = @_;
  $db   ||= 'combust';
  $attr = {} unless ref $attr;

  carp "$$ Develooper::DB::open_db called during server startup" if $Apache::Server::Starting;

  my $imadbi       = delete $attr->{imadbi} ? '-ima' : '';

  my $lock         = delete $attr->{lock};
  my $lock_timeout = delete $attr->{lock_timeout};
  my $lock_name    = delete $attr->{lock_name};

  # default to RaiseError=>1 but allow caller to override
  my $RaiseError = $attr->{RaiseError};
  $RaiseError = (defined $RaiseError) ? $RaiseError : 1;  

  my $dbh = $dbh{$db . $imadbi};
  
  unless ($dbh and $dbh->ping()) {
	my ($host, @args) = read_db_connection_parameters();

	$dbh = DBI->connect(@args, {
		%$attr,
		RaiseError => 0,    # override RaiseError for connect
        AutoCommit => 1,    # make it explicit
    });

	if ($dbh) {
	  $dbh->{RaiseError} = $RaiseError;
	  $dbh{$db . $imadbi} = $dbh;
	}
	else {
	  carp "Could not open $args[0] on $host: $DBI::errstr" if $RaiseError;
	  # fall through if not RaiseError
	}
  }

  if ($lock) {
	$lock_timeout = 180 unless $lock_timeout;
	$lock_name = $0 unless $lock_name;
	my $lockok = $dbh && $dbh->do(qq[SELECT GET_LOCK("$lock_name",$lock_timeout)]);
	croak "Unable to get $lock_name lock for $0\n" unless $lockok;
  }
  
  # return handle; undef if connect failed and RaiseError is false
  return $dbh;
}

END {
    local ($!, $?);
    while (my ($db, $handle) = each %dbh) {
        $handle->disconnect() if $handle->{Active};
        delete $dbh{$db};
    }
}

1;
