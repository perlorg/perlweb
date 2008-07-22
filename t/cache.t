use Test::More qw(no_plan);
use strict;
use Data::Dumper;

use_ok('Combust::Cache');

for my $cache_backend (qw(dbi memcached)) {
    ok( Combust::Cache->backend($cache_backend), "set backend to $cache_backend" );
    ok( my $cache = Combust::Cache->new( type => "test" ),
        "new Cache object (backend $cache_backend)"
    );

    ok( $cache->store( id => "test1", data => "T1" ), "store simple data" );
    ok( my $d = $cache->fetch( id => "test1" ), "fetch simple data" );
    is( $d->{data}, "T1", "test simple data" );

    my $long_id = '1234567890' x (100);
    ok( $cache->store( id => $long_id, data => "T1" ), "store long key" );
    ok( my $d = $cache->fetch( id => $long_id ), "fetch simple data" );
    is( $d->{data}, "T1", "test simple data" );

    ok( $cache->store( id => "test2", data => ["T2"] ), "store reference data" );
    ok( $d = $cache->fetch( id => "test2" ), "fetch reference data" );
    is_deeply( $d->{data}, ["T2"], "test reference data" );

    ok( $cache->store( id => "test3", data => "T3", meta_data => { m => "x1" } ),
        "store meta_data" );
    ok( $d = $cache->fetch( id => "test3" ), "fetch meta_data" );
    is( $d->{data}, "T3", "test meta_data test data" );
    is_deeply( $d->{meta_data}, { m => "x1" }, "test meta_data" );

    ok( $cache->store( id => "test4", data => "T4a" ), "store" );
    ok( $d = $cache->fetch( id => "test4" ), "fetch with id" );
    is( $d->{data}, "T4a", "test data T4a" );
    ok( $cache->store( data => "T4b" ), "store without id" );
    ok( $d = $cache->fetch( id => "test4" ), "fetch data stored without id" );
    is( $d->{data}, "T4b", "test data T4b ($cache_backend)" );

    is( $cache->fetch( id => "no_such_key" . rand ),
        undef, "get undefined return from non-existing cache key" );

    # 100KB data
    my $large_data = '1234567890' x (10_000);
    ok( $cache->store( id => "test_large", data => $large_data ), "store large data" );
    ok( my $d = $cache->fetch( id => "test_large" ), "fetch large data" );
    ok( $d->{data} eq $large_data, "test large data" );

    ok( $cache->delete( id => "test_large" ), "delete" );
    is( $cache->fetch( id => "test_large" ), undef, "deleted data is gone" );

    {
        local $Combust::Cache::namespace = "test5-a";
        ok( $cache->store( id => "test5", data => "T5a" ), "store - namespace a" );
        {
            local $Combust::Cache::namespace = "test5-b";
            ok( $cache->store( id => "test5", data => "T5b" ), "store - namespace b" );
            ok( $d = $cache->fetch( id => "test5" ), "fetch with id - ns b" );
            is( $d->{data}, "T5b", "test data T5b - ns b" );
        }
        ok( $d = $cache->fetch( id => "test5" ), "fetch with id - ns a" );
        is( $d->{data}, "T5a", "test data T5a - ns a" );
    }

}

ok( my $cache = Combust::Cache->new( type => "test" ), "new Cache object" );
ok( $cache->backend('memcached'), "change backend to memcached" );
is( $cache->backend, "memcached", "backend is memcached" );
isa_ok( $cache, "Combust::Cache::Memcached" );
ok( $cache->backend('dbi'), "change backend to dbi" );
isa_ok( $cache, "Combust::Cache::DBI" );

# test setting an invalid backend

#warn Data::Dumper->Dump([\$d], [qw(d)]);


__END__

# These don't actually use Test::Benchmark, no idea what's up with that. :)
if ($ENV{CACHE_BENCHMARK}) { 
   my $HAVE_TEST_BENCHMARK;
   eval 'use Test::Benchmark';
   $HAVE_TEST_BENCHMARK = 1 unless ($@);

 SKIP: {
       skip 'Need Test::Benchmark for this test', 0 unless $HAVE_TEST_BENCHMARK
       
    my $cache = Combust::Cache->new(type=>"test");
    use Benchmark qw(timethese);
    timethese(50,
              {
               'memcached_store' => sub {
                   $cache->backend('memcached');
                   store_many($cache);
               },
               'dbi_store' => sub {
                   $cache->backend('dbi');
                   store_many($cache);
               }
              },
             );
       
       $^W=0;
       
       timethese(50,
                 {
                  'memcached_fetch' => sub {
                      $cache->backend('memcached');
                      fetch_many($cache);
                  },
                  'dbi_fetch' => sub {
                      $cache->backend('dbi');
                      fetch_many($cache);
                  }
                 },
                );
}

sub store_many {
  my $data = { test => "foo", blah => join("", ("x")x5000) };
  my $cache = shift;
  for my $i (50..1000) {
    $cache->store(id => "b$i", data => $data);
  }
}


sub fetch_many {
  my $cache = shift;
  for my $i (1..1050) {
    $cache->fetch(id => "b$i");
  }
}
