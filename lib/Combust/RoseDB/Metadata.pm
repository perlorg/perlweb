package Combust::RoseDB::Metadata;
use strict;
use base qw(Rose::DB::Object::Metadata);

sub new {
  shift->SUPER::new(
    auto_load_related_classes   => 0,
    default_update_changes_only => 1,
    default_insert_changes_only => 1,
    @_
  );
}

sub setup {
  my $meta = shift;
  my $class = $meta->class;

  my $meth = $class->can('COMBUST_PRE_SETUP');

  $meta->SUPER::setup( $meth ? $meth->($meta, @_) : @_ );

  if (my $post = $class->can('COMBUST_POST_SETUP')) {
    $post->($meta);
  }
}

sub initialize {
  my $meta = shift;
  my $class = $meta->class;

  my $meth = $class->can('COMBUST_PRE_INIT');

  $meta->SUPER::initialize( $meth ? $meth->($meta, @_) : @_ );
}

1;
