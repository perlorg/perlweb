package Combust::RoseDB::Scaffold;
use strict;

sub filter_tables { # Return 0 to exclude a table
  my $self  = shift;
  my $db    = shift;
  my $table = shift;

  return $table !~ /^combust_ | ^(old|te?mp)_ | _te?mp$/ix;
}

sub cache_table { # Return 1 to make a table be cached
  my $self = shift;
  my $meta = shift;
  my $table = $meta->table;

  return 0;
}

sub object_base_classes {
  my $self = shift;
  my $db_name = shift;

  return qw(Combust::RoseDB::Object::toJson);
}

sub class_pre_init_hook {
  my $self = shift;
  my $meta = shift;

  return;
}

sub db_model_class { # Return the model class name for a database
  my $self = shift;
  my $db_name = shift;

  return;
}

sub convention_manager { # Return the convention manager class name for a database
  my $self = shift;
  my $db_name = shift;

  return 'Combust::RoseDB::ConventionManager';
}

1;

