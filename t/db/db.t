use strict;
use Test::More;

BEGIN {
  eval "use DBD::SQLite";
  plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 10);
}

BEGIN { 
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/db/db.conf";
  use_ok('Combust::Config');
  use_ok('Combust::DB', qw(db_open));
}

ok(my $dbh1 = db_open('test1'), "db_open test1");
ok(my $dbh2 = db_open('test2'), "db_open test2");

my $table  = 'create table foo (test char(20))';
my $insert = 'insert into foo values (?)';
my $select = 'select test from foo';

ok($dbh1->do($table), "create table 1");
ok($dbh2->do($table), "create table 2");
ok($dbh1->do($insert, {}, "n1"), "insert 1");
ok($dbh2->do($insert, {}, "n2"), "insert 2");
is(($dbh1->selectrow_array($select))[0], "n1", "select n1");
is(($dbh2->selectrow_array($select))[0], "n2", "select n2");

unlink "t/db/test1.db";
unlink "t/db/test2.db";
