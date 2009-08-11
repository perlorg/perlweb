package Combust::RoseDB;

use strict;
use Combust::Config;
use Combust::RoseDB::Column::Point;
use Combust::RoseDB::Constants qw(DB_DOWN DB_BOUNCED DB_UP);
use Combust::RoseDB::Transaction;
use Combust::Logger ();
use DBI;
use base 'Rose::DB';


use Rose::Class::MakeMethods::Generic (
    'scalar' => [
        qw(combust_thread_id)
    ]
);

use Rose::Object::MakeMethods::Generic (
    'scalar' => [
        qw(combust_model)
    ]
);

BEGIN {
  __PACKAGE__->db_cache; # Force subclasses to inherit cache
  __PACKAGE__->use_private_registry;

  my %dbs = Combust::Config::_setup_dbs();
  
  (values %dbs)[0]->{default} = 1 if 1 == keys %dbs;
  
  while (my($db_name, $db_cfg) = each %dbs) {
    $db_cfg = $dbs{$db_cfg->{alias}} if $db_cfg->{alias};

    my $dsn = $db_cfg->{data_source}
      or do { require Data::Dumper; die Data::Dumper::Dumper($db_cfg) };
  
    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
        or die "Can't parse DBI DSN '$dsn'";

    my %opt = (
      domain   => $db_cfg->{domain} || 'combust',
      type     => $db_cfg->{type} || $db_name,
      database => $db_cfg->{database} || ($dsn=~ /[:;]database=(\w+)/)[0] || $db_name,
      driver   => $driver,
      dsn      => $dsn,
      username => $db_cfg->{user},
      password => $db_cfg->{password},
    );
    $opt{server_time_zone} = $db_cfg->{time_zone} if $db_cfg->{time_zone};

    if ($db_cfg->{sql_mode} and $db_cfg->{sql_mode} =~ /(\S+)/) {
      push @{$opt{post_connect_sql}}, "SET sql_mode = '$1'";
    }
    if ($db_cfg->{time_zone} and $db_cfg->{time_zone} =~ /(\S+)/) {
      push @{$opt{post_connect_sql}}, "SET time_zone = '$1'";
    }

    $opt{connect_options}{mysql_enable_utf8} = 1;
    push @{$opt{post_connect_sql}}, 'SET NAMES utf8';

    __PACKAGE__->register_db(%opt);
    
    if ($db_cfg->{default}) {
      __PACKAGE__->default_type($opt{type});
      __PACKAGE__->default_domain($opt{domain});
    }
  }
}

sub init_db_info {
  my $self = shift;
  # We must disable mysql auto-reconnects, for two reasons
  # 1) If a reconnect happens, then the post_connect-sql would not be run, potentially leaving us with a bad connection
  # 2) After a timeout ->ping would reconnect, by ->{Active} is still false. This causes RDBO issues
  $self->mysql_auto_reconnect(0);
  $self->SUPER::init_db_info(@_);
}


sub ping {
  my $self      = shift;
  my $thread_id = $self->combust_thread_id;

  my $dbh = eval { local $SIG{__DIE__}; $self->dbh };
  my $up            = $dbh && $dbh->ping;
  my $new_thread_id = $up  && $dbh->{mysql_thread_id};

  if ($thread_id) {    # Last check connection was ok
    unless ($up) {
      $self->dbh(undef);    # Force re-connect
      $dbh = eval { local $SIG{__DIE__}; $self->dbh };
      $up            = $dbh && $dbh->ping;
      $new_thread_id = $up  && $dbh->{mysql_thread_id};
    }

    if ($up) {
      return DB_UP if $thread_id == $new_thread_id;
      $self->combust_thread_id($new_thread_id);
      Combust::Logger::logwarn( "Bounced database connection to '" . $self->type . "'\n" );
      return DB_BOUNCED;
    }
  }
  elsif ( defined $thread_id ) {    # Last check connection was down
    if ($up) {
      $self->combust_thread_id($new_thread_id);
      Combust::Logger::logwarn( "Reconnected database connection to '" . $self->type . "'\n" );
      return DB_BOUNCED;
    }
  }
  else {                            # First time through
    if ($up) {
      $self->combust_thread_id($new_thread_id);
      if ( $dbh->{auto_reconnects_ok} ) {
        Combust::Logger::logwarn( "Bounced database connection to '" . $self->type . "'\n" );
        return DB_BOUNCED;
      }
      else {
        return DB_UP;
      }
    }
    else {
      $self->dbh(undef);            # Force re-connect
      $dbh = eval { local $SIG{__DIE__}; $self->dbh };
      $up = $dbh && $dbh->ping;
      if ($up) {
        $new_thread_id = $dbh->{mysql_thread_id};
        $self->combust_thread_id($new_thread_id);
        Combust::Logger::logwarn( "Bounced database connection to '" . $self->type . "'\n" );
        return DB_BOUNCED;
      }
    }
  }

  $self->combust_thread_id(0);      # Signal connection as down
  $self->dbh(undef);                # Force re-connect

  Combust::Logger::logwarn( "Lost database connection to '" . $self->type . "'\n" )
    if ($thread_id or !defined($thread_id));

  return DB_DOWN;
}


sub check_all_db_status {
  my $class = shift;
  my $status = DB_UP;

  # Return minimum status from all Dbs checked

  my @db = map { $_->db } __PACKAGE__->db_cache->db_cache_entries;
  foreach my $db (@db) {
    my $ping = $db->ping;
    $status = $ping if $ping < $status;
  }

  return $status;
}


sub begin_scoped_work {
  my $db = shift;
  Combust::RoseDB::Transaction->new($db);
}

sub DESTROY { } # Avoid disconnect being called

# Ensure if used inside apache, that we clear the DB connection cache during ChildInit
if ($ENV{MOD_PERL}) {
  my ($software, $version) = $ENV{MOD_PERL} =~ /^(\S+)\/(\d+(?:[\.\_]\d+)+)/;
  my $handler = sub { Combust::RoseDB->db_cache->clear; 0; };
  if ($version >= 2.0) {
    require Apache2::ServerUtil;
    Apache2::ServerUtil->server->push_handlers(PerlChildInitHandler => $handler);
  }
  else {
    require Apache;
    Apache->push_handlers(PerlChildInitHandler => $handler);
  }

}


1;

__END__

# This has been put into the upstream code now

package Rose::DB::MySQL;

sub parse_set {
    my($self) = shift;
    
    return $_[0]  if(ref $_[0]);
    return [ @_ ] if(@_ > 1);

    my $val = $_[0];
    
    return undef  unless(defined $val);

    my @set = split /,/, $val;

    return \@set;
}

sub format_set {
    my($self) = shift;

    my @set = (ref $_[0]) ? @{$_[0]} : @_;
    
    return undef  unless(@set && defined $set[0]);

    return join(',', map {
        if(!defined $_)
          {
              Carp::croak 'Undefined value found in array or list passed to ',
                  __PACKAGE__, '::format_set()';
          }
        else {
            $_
        }
    } @set);
}


1;
