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
__END__
=head1 NAME
  Combust::Cache - Caching module

=head1 SYNOPSIS

  my $cache = Combust::Cache->new(type => 'dev.perl');

  $cache->store(id => "html;/index.html",
                data => $output,
                meta_data => { content_type => 'text/html' });

  my $data = $cache->fetch(id => "html;/index.html");
  print $data->{data},
         " with type ", $data->{meta_data}->{content_type},
         " created on ", $data->{created};


  # store complex data using the id specified in fetch
  $data = $cache->fetch(id => "rss;somefeed");
  $cache->store(data => { rss => $rss, meta => $metadata }); 
 
=head1 CONSTRUCTOR

=over 4

=item new

requires one parameter, "type".  The type is the higest level in the
cache key name space and should be used to separate use of the cache
in different parts of the system.

Examples would be "rssloader", "www.site.com-html", "pod converter
cache".

=back

=head1 METHODS

=over 4

=item store( id => C<ID>, expires => C<EXPIRES>, purge_key => C<PURGE_KEY>, data => C<DATA>, meta_data => C<METADATA> )

Store data to the cache.

C<ID> is the cache key.  Optional, will use the last id passed to the
fetch method if not specified here.

The number of seconds before the entry will expire is passed in as
C<EXPIRES>. Defaults to 7200 (2 hours).

C<DATA> is the data to be stored.  Only required field.  Will be
serialized with Storable if it's a reference.

C<META_DATA>: Hash reference to meta data stored with the data entry.
Can for example contain the mime type of the data.

The C<PURGE_KEY> is like C<ID> but only used for purging data.  Can be
used to easily purge part of the cache when data is updated.



=item fetch ( id => C<ID> )

Fetches data from the cache.  The id is stored and reused for a
subsequent call to C<store>.  Returns a hash reference with the
following data

=over 4

=item C<data>

Whatever was stored. 

=item C<meta_data>

The hash reference that was stored; otherwise an empty hash ref.

=item C<created_timestamp>

When the cache entry was created; as a unix timestamp.

=item C<created>

When the cache entry was created; in MySQL datatime format.

=back

=HEAD1 TODO

=over 4

=item Method to purge entries with a certain purge_key and maybe force expire entries by id too.

=item Support things like "3h" or "180m" for the expires parameter.  

=back

=cut




