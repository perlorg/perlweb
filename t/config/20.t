use Test::More;
use strict;

BEGIN {
  unless ($ENV{CBROOT}) {
    plan skip_all => 'ENV{CBROOT} not set';
    exit 0;
  }
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/20.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->port, 20000, "configured port"); 
ok($c->sites_list == 2, "two sites");
isa_ok($c->sites, "HASH", "sites hashref"); # TODO - check the data

is($c->base_url('test1'), 'http://test1.local', 'base_url');

done_testing();
