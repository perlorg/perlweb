package CPANNotify::DBI;
use strict;
use base qw(Class::DBI::mysql);
use Combust::DB qw(db_open);

sub dbh {
  shift->db_Main;
}

sub db_Main { 
  my $class = shift;
  return db_open('combust', {$class->_default_attributes})
}

1;
