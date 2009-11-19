package Combust::RoseDB::Metadata;
use strict;
use base qw(Rose::DB::Object::Metadata);
use JSON::XS;
use Carp qw(cluck);
use Sub::Install qw(install_sub);
use Rose::DB::Object::Constants
  qw(STATE_LOADING STATE_SAVING);

use namespace::clean;

my $json = JSON::XS->new;

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

sub setup_json_columns {
  my $meta = shift;
  my $class = $meta->class;

  foreach my $column ( map { $meta->column($_) } @_ ) {
    $column->add_trigger(
      inflate => sub {
        shift;    # object;
        my $v = shift or return undef;
        return $v if ref($v);
        my $r = eval { $json->decode($v) }
          or cluck($meta->table,".",$column->name,": ", $@);
        $r;
      }
    );
    $column->add_trigger(
      deflate => sub {
        shift;    # object;
        my $h = shift or return undef;
        $json->encode($h);
      }
    );

    {
      my $accessor = $column->accessor_method_name;
      my $code     = sub {
        my $self = shift;
        $self->$accessor([]) if @_;    # make sure marked as dirty when setting
        my $key = @_ ? STATE_LOADING : STATE_SAVING;
        local $self->{$key} = 1;      # Fake DB access so we can set/get raw JSON value
        $self->$accessor(@_);
      };

      install_sub(
        { into => $class,
          as   => "${accessor}_json",
          code => $code,
        }
      );
    }
  }
}

1;
