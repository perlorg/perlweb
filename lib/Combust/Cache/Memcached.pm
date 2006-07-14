package Combust::Cache::Memcached;
use strict;
use Carp qw(carp);
use base qw(Combust::Cache);
use Cache::Memcached;

my $memd = new Cache::Memcached {
  'servers' => [ "127.0.0.1:11211" ],
    'debug' => 0,
      'compress_threshold' => 10_000,
    };


sub store {
  my ($self, %args) = @_;
  my $id        = ($args{id} || $self->{fetched_id}) 
    or carp "No id specified" and return;

  my $data      = defined $args{data}
                    ? $args{data}
                    : (carp "No data passed to cache" and return);

  my $type = $self->{type};

  my $metadata  = ($args{meta_data} and ref $args{meta_data} eq "HASH"
  		     ? $args{meta_data}
		     : undef);

  my $expire    = time + ($args{expire} || $args{expires} || 7200);

  $memd->set("$type;$id", { data => $data,
			    meta_data => $metadata,
			    created_timestamp => time,
			  }, $expire);
}

sub fetch {
  my ($self, %args) = @_;

  my $id = $args{id} or carp "No id specified" and return;
  my $type = $self->{type};

  $self->{fetched_id} = $id;

  local $^W = 0;
  my $row = $memd->get("$type;$id") or return undef;
  
  return $row;

}

sub delete {
  my ($self, %args) = @_;
  my $id        = ($args{id} || $self->{fetched_id}) 
    or carp "No id specified" and return;

  my $type = $self->{type};

  $memd->delete("$type;$id");
}

1;
