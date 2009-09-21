use Test::More;
use strict;

BEGIN {
  unless ($ENV{CBROOT}) {
    plan skip_all => 'ENV{CBROOT} not set';
    exit 0;
  }
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/50.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->base_url('test'), 'https://test.local', 'base_url');

done_testing();
