package Combust::Cache;
use strict;
use Develooper::DB qw(db_open);
use Carp qw(carp);
use Storable qw(nfreeze thaw);

# TODO:
#   - support passing a scalar ref to store() ?
#

sub new {
  my ($proto, %args) = (shift, @_);
  my $class = ref $proto || $proto;
  my $type  = $args{type}|| '';
  my $self = { type => $type };
  bless( $self, $class);
}

sub fetch {
  my ($self, %args) = @_;

  my $id = $args{id} or carp "No id specified" and return;
  my $type = $self->{type};

  $self->{fetched_id} = $id;

  my $dbh = db_open;

  my $row = $dbh->selectrow_hashref
    (
     q[SELECT created, data, metadata, serialized,
              UNIX_TIMESTAMP(created) as created_timestamp
       FROM combust_cache
       WHERE 
       id = ?
       AND type = ?
       AND expire > NOW()
      ],
     {},
     $id,
     $type
    );

  return undef unless $row;

  if ($row->{serialized}) {
    $row->{data} = thaw $row->{data};
  }
  
  $row->{meta_data} = delete $row->{metadata};
  $row->{meta_data} = $row->{meta_data}
                        ? thaw $row->{meta_data}
			: {};  
     
  $row;
  
}

sub store {
  my ($self, %args) = @_;
  my $id        = ($args{id} || $self->{fetched_id}) 
    or carp "No id specified" and return;
  my $purge_key = $args{purge_key} || undef;
  my $data      = defined $args{data}
                    ? $args{data}
                    : (carp "No data passed to cache" and return);

  my $type = $self->{type};

  my $metadata  = ($args{meta_data} and ref $args{meta_data} eq "HASH"
  		     ? $args{meta_data}
		     : undef);

  my $expire    = time + ($args{expire} || 7200);

  my $serialized = 0;

  if (ref $data) {
    $data = nfreeze($data);
    $serialized = 1;
  }

  $metadata = nfreeze($metadata)
    if (defined $metadata);

  my $dbh = db_open;
  $dbh->do(q[replace into combust_cache
	     (id, type, purge_key, data, metadata, serialized, expire)
	     VALUES (?,?,?,?,?,?,FROM_UNIXTIME(?))],
	   {},
	   $id,
           $type,
           $purge_key,
           $data, 
           $metadata,
           $serialized, 
           $expire,
	  );
}


1;
