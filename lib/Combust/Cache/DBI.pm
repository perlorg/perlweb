package Combust::Cache::DBI;
use strict;
use base qw(Combust::Cache);
use Carp qw(carp);
use Combust::DB qw(db_open);
use Storable qw(nfreeze thaw);
use vars qw($HAVE_ZLIB);

BEGIN {
    $HAVE_ZLIB = eval "use Compress::Zlib (); 1;";
}

use constant F_STORABLE => 1;
use constant F_COMPRESS => 2;

# size savings required before saving compressed value
use constant COMPRESS_THRESHOLD => 10_000;
use constant COMPRESS_SAVINGS => 0.20; # percent

sub fetch {
  my ($self, %args) = @_;

  my $id = $self->_normalize_id($args{id}) or carp "No id specified" and return;
  my $type = $self->{type};

  $self->{fetched_id} = $id;

  my $dbh = db_open('combust')
    or return;

  my $sth = $dbh->prepare_cached(
     q[SELECT created, data, metadata, serialized,
              UNIX_TIMESTAMP(created) as created_timestamp
       FROM combust_cache
       WHERE id = ? AND type = ? AND expire > NOW()
      ]
  );
  my $row = $dbh->selectrow_hashref($sth, undef, $id, $type);

  return undef unless $row;

  $row->{serialized} ||= 0;

  $row->{data} = Compress::Zlib::memGunzip($row->{data})
    if $HAVE_ZLIB && $row->{serialized} & F_COMPRESS;

  if ($row->{serialized} & F_STORABLE) {
    $row->{data} = thaw $row->{data};
  }
  else {
      utf8::decode($row->{data});
  }
  
  $row->{meta_data} = delete $row->{metadata};
  $row->{meta_data} = $row->{meta_data}
                        ? thaw $row->{meta_data}
			: {};  
     
  $row;
  
}

sub store {
  my ($self, %args) = @_;
  my $id        = ($self->_normalize_id($args{id}) || $self->{fetched_id}) 
    or carp "No id specified" and return;

  my $purge_key = $args{purge_key} || undef;
  my $data      = defined $args{data}
                    ? $args{data}
                    : (carp "No data passed to cache" and return);

  my $type = $self->{type};

  my $metadata  = (ref $args{meta_data} eq "HASH"
  		     ? $args{meta_data}
		     : undef);

  my $expire    = time + ($args{expire} || $args{expires} || 7200);

  my $serialized = 0;

  if (ref $data) {
    $data = nfreeze($data);
    $serialized |= F_STORABLE;
  }

  $metadata = nfreeze($metadata) if (defined $metadata);

  my $len = length($data);
  if ($HAVE_ZLIB && $len >= COMPRESS_THRESHOLD) {
      my $c_val = Compress::Zlib::memGzip($data);
      my $c_len = length($c_val);
      
      # do we want to keep it?
      if ($c_len < $len*(1 - COMPRESS_SAVINGS)) {
          $data = $c_val;
          $len = $c_len;
          $serialized |= F_COMPRESS;
      }
  }

  my $dbh = db_open()
      or return;
  return $dbh->do(q[replace into combust_cache
	     (id, type, purge_key, data, metadata, serialized, expire)
	     VALUES (?,?,?,?,?,?,FROM_UNIXTIME(?))],
	   undef,
	   $id,
           $type,
           $purge_key,
           $data, 
           $metadata,
           $serialized, 
           $expire,
	  );
}

sub delete {
  my ($self, %args) = @_;
  my $id        = ($args{id} || $self->{fetched_id}) 
    or carp "No id specified" and return;
  my $type = $self->{type};

  my $dbh = db_open();
  $dbh->do(q[delete from combust_cache where id=? and type=?], undef, $id, $type);
}



1;


__END__

Parts are from Cache::Memcached by Brad Fitzpatrick
