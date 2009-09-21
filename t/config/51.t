use Test::More;
use strict;

BEGIN {
  unless ($ENV{CBROOT}) {
    plan skip_all => 'ENV{CBROOT} not set';
    exit 0;
  }
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/51.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->config_file, $ENV{CBCONFIG}, 'config_file');

is($c->base_url('test'), 'http://test.local:8000', 'base_url');

done_testing();