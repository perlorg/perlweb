package Develooper::DB;
use Combust::DB;
use Exporter::Lite;
@EXPORT = qw(db_open);
use strict;

sub db_open {
  Combust::DB::db_open(@_);
}

1;
