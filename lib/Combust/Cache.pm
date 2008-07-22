package Combust::Cache;
use strict;
use Carp qw(carp);
use Digest::MD5 qw(md5_hex);

use Combust::Cache::DBI;
eval { require Combust::Cache::Memcached };

my $id_max_length = 64;

our $namespace = undef;

# TODO:
#   - support passing a scalar ref to store() ?
#

my $default_backend = 'dbi';

sub new {
  my ($proto, %args) = (shift, @_);
  my $class   = ref $proto || $proto;
  my $type    = $args{type}|| '';
  my $backend = $args{backend};
  my $self = { type => $type };
  # bless( $self, $class);
  bless_backend($self, $class, $backend);
}

sub bless_backend {
  my ($self, $class, $backend) = @_;
  $backend ||= $class->backend;
  my $_class;
  $_class = 'Combust::Cache::DBI' if $backend eq "dbi";
  $_class = 'Combust::Cache::Memcached' if $backend eq "memcached";
  bless $self, $_class if $_class;
}

sub backend {
  my ($self, $backend) = @_;

  carp "$backend is not a valid Combust::Cache storage backend"
      and $backend = undef 
	if $backend and $backend !~ m/^(dbi|memcached)$/;

  if ($backend) {
    if (ref $self) {
      bless_backend($self, $self, $backend);
    }
    else {
      $default_backend = $backend;
    }
  }

  # return $self->{_backend} if ref $self and $self->{_backend};
  return $default_backend;
}

sub _normalize_id {
    my ($self, $id) = @_;
    return unless defined $id;
    $id = "$namespace;$id" if defined $namespace;
    if (length $id > ($id_max_length - 4)) {
        $id = "md5-" . md5_hex($id);
    }
    $id;
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




