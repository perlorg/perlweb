package Combust::DB::Object;
use strict;
use Combust::RoseDB;
# use CN::DB::Column::Point;
# use CN::DB::ConventionManager;

{
  package Combust::DB::Object::Metadata::Base;

  use base qw(Rose::DB::Object::Metadata);

  sub new {
    shift->SUPER::new(
      auto_load_related_classes   => 0,
      default_update_changes_only => 1,
      default_insert_changes_only => 1,
      @_
    );
  }
}

# TODO: move this to a configuration file of sorts
our %class_type = qw(
  NP::DB::Object          ntppool
);

while (my($class,$type) = each %class_type) {
  (my $schema = $class) =~ s/::Object//;
  $schema =~ s/::DB/::Model/;

  my $defn = <<EOS;
    {
      package ${class}::Metadata;
      our \@ISA = qw(Combust::DB::Object::Metadata::Base);
      sub registry_key { '${class}::Metadata' }
    }
    {
      package $class;
      use base qw(Combust::RoseDB::Object::toJson Rose::DB::Object);

      sub init_db { shift; Combust::RoseDB->new( \@_, type => '$type' ) }
      sub meta_class { '${class}::Metadata' }
      sub schema     { '$schema' }
    }
    {
      package ${class}::Cached;
      use base qw(Combust::RoseDB::Object::toJson Rose::DB::Object::Cached);

      sub init_db { shift; Combust::RoseDB->new( \@_, type => '$type' ) }
      sub meta_class { '${class}::Metadata' }
      sub schema     { '$schema' }
    }
    1;
EOS
  eval $defn or die $defn,$@;
}

1;
