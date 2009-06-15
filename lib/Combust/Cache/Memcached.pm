package Combust::Cache::Memcached;
use strict;
use Carp qw(carp);
use base qw(Combust::Cache);
use Combust;

my $libmemcached;

BEGIN {
    $libmemcached = eval { require Cache::Memcached::libmemcached };
    unless ($libmemcached) {
        require Cache::Memcached;
    }
}

my $config = Combust->config;

my $module =
  $libmemcached
  ? 'Cache::Memcached::libmemcached'
  : 'Cache::Memcached';

my $memd = $module->new(
    {   'servers'            => [$config->memcached_servers],
        'debug'              => 0,
        'compress_threshold' => 5_000,
    }
);

# warn Data::Dumper->Dump([\$memd], [qw(memd)]);

sub store {
  my ($self, %args) = @_;
  my $id        = ($self->_normalize_id($args{id}) || $self->{fetched_id}) 
    or carp "No id specified" and return;

  my $data      = defined $args{data}
                    ? $args{data}
                    : (carp "No data passed to cache" and return);

  my $expire    = time + ($args{expire} || $args{expires} || 7200);
      
  if ($args{plain}) {
      return $memd->set($id, $data, $expire);
  }

  my $metadata  = ($args{meta_data} and ref $args{meta_data} eq "HASH"
                   ? $args{meta_data}
                   : undef);
  
  return $memd->set($id, { data => $data,
                           meta_data => $metadata,
                           created_timestamp => time,
                         }, 
                    $expire
                   );
}

sub fetch {
  my ($self, %args) = @_;

  my $id = $args{id} or carp "No id specified" and return;

  $id = $self->_normalize_id($id);

  $self->{fetched_id} = $id;

  local $^W = 0;
  my $row = $memd->get($id) or return undef;
  
  return $row;

}

sub fetch_multi {
    my ($self, @ids) = @_;

    @ids = map { $self->_normalize_id($_) } @ids;

    my $rv = $memd->get_multi(@ids);
    return unless $rv;

    my $prefix = join ";", grep { defined } $Combust::Cache::namespace, $self->{type}, "";
    my $prefixre = qr/^$prefix/;

    for my $k (keys %$rv) {
        my $k2 = $k;
        $k2 =~ s/$prefixre//;
        $rv->{$k2} = delete $rv->{$k};
    }
    $rv;
}



sub incr { 
    my ($self, $id, $incr) = @_;
    $incr = 1 unless $incr;
    $id = $self->_normalize_id($id);

    my $rv = $memd->incr($id, $incr);
    return $rv if $rv;

    # if $id isn't set, incr will fail
    $rv = $memd->add($id, $incr);
    return $incr if $rv;

    # catch unlikely but possible race condition
    return $memd->incr($id, $incr);
}


sub delete {
  my ($self, %args) = @_;
  my $id        = ($self->_normalize_id($args{id}) || $self->{fetched_id}) 
    or carp "No id specified" and return;

  $memd->delete($id);
}

sub _normalize_id {
    my ($self, $id) = @_;
    # allow falling back to using $self->{fetched_id} in the calling methods
    return unless $id; 
    $id = join ';', $self->{type}, $id;
    $self->SUPER::_normalize_id($id);
}

1;
