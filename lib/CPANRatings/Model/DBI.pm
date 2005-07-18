package CPANRatings::Model::DBI;
use strict;
use base qw(Class::DBI::mysql);
use Develooper::DB qw(db_open);

sub db_Main { 
  my $class = shift;
  return db_open('combust', {$class->_default_attributes}) }
1;
