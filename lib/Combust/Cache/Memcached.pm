package Combust::Cache::Memcached;
use strict;
use Carp qw(carp);
use base qw(Combust::Cache);
use Combust::Config; 

use Digest::MD5 qw(md5_hex);
use Cache::Memcached;


my $config = Combust::Config->new();

my $memd = new Cache::Memcached {
  'servers' => [ $config->memcached_servers ],
  'debug' => 0,
  'compress_threshold' => 10_000,
};

# warn Data::Dumper->Dump([\$memd], [qw(memd)]);

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

  $id = md5_hex($id) if length($id) > 64;

  $memd->set("$type;$id", { data => $data,
			    meta_data => $metadata,
			    created_timestamp => time,
			  }, $expire);
}

sub fetch {
  my ($self, %args) = @_;

  my $id = $args{id} or carp "No id specified" and return;
  my $type = $self->{type};

  $id = md5_hex($id) if length($id) > 64;

  $self->{fetched_id} = $id;

  local $^W = 0;
  my $row = $memd->get("$type;$id") or return undef;
  
  return $row;

}

sub fetch_multi {
    my ($self, ) = @_;

    

}

sub delete {
  my ($self, %args) = @_;
  my $id        = ($args{id} || $self->{fetched_id}) 
    or carp "No id specified" and return;

  my $type = $self->{type};

  $memd->delete("$type;$id");
}

1;
