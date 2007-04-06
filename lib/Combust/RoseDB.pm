package Combust::RoseDB;

use strict;
use Combust::Config;
use Combust::RoseDB::Column::Point;
use DBI;
use base 'Rose::DB';

BEGIN {
  __PACKAGE__->use_private_registry;

  # Cause DBI to use cached connections. Apache::DBI also sets this
  # and we don't want to override that
  $DBI::connect_via = "connect_cached" if $DBI::connect_via eq 'connect';
  
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


    __PACKAGE__->register_db(%opt);
    
    if ($db_cfg->{default}) {
      __PACKAGE__->default_type($opt{type});
      __PACKAGE__->default_domain($opt{domain});
    }
  }
}

our $once;
sub dbh {
  my $self = shift;
  my $dbh = $self->SUPER::dbh(@_);
  unless ($once) {
    local $once = 1;
    $self->retain_dbh; # Prevent RDB calling disconnect
  }
  $dbh;
}

sub DESTROY { } # Avoid disconnect being called

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
