package Develooper::DB;
use Combust::DB;
use base(Exporter);
@EXPORT = qw(db_open);
use strict;

sub db_open {
  Combust::DB::db_open(@_);
}

1;
