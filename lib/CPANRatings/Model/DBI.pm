package CPANRatings::Model::DBI;
use strict;
use base qw(Class::DBI::mysql);
use Develooper::DB qw(db_open);

sub db_Main { return db_open('combust') }

1;
