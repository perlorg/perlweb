use Test::More qw(no_plan);
use strict;

use Data::Dumper;

use_ok('Combust::Cache');

ok(my $cache = Combust::Cache->new(type=>"test"), "new Cache object");

ok($cache->store(id => "test1", data => "T1"), "store simple data");
ok(my $d = $cache->fetch(id => "test1"), "fetch simple data");
is($d->{data}, "T1", "test simple data");

ok($cache->store(id => "test2", data => ["T2"]), "store reference data");
ok(my $d = $cache->fetch(id => "test2"), "fetch reference data");
is_deeply($d->{data}, ["T2"], "test reference data");

ok($cache->store(id => "test3", data => "T3", meta_data => { m => "x1"} ), "store meta_data");
ok(my $d = $cache->fetch(id => "test3"), "fetch meta_data");
is($d->{data}, "T3", "test meta_data test data");
is_deeply($d->{meta_data}, {m=>"x1"}, "test meta_data"); 

is($cache->fetch(id => "no_such_key"), undef, "get undefined return from non-existing cache key");



#warn Data::Dumper->Dump([\$d], [qw(d)]);
