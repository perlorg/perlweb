package Combust::RoseDB::Manager;

use base qw(Rose::DB::Object::Manager);

sub fetch {
  my $self = shift;
  my $obj = $self->object_class->new(@_);
  $obj->load(speculative => 1) ? $obj : undef;
}

sub fetch_or_create {
  my $self = shift;
  my $obj = $self->object_class->new(@_);
  $obj->load(speculative => 1);
  $obj;
}

sub create {
  shift->object_class->new(@_);
}

1;
