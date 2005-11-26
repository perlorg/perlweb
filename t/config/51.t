use Test::More qw(no_plan);
use lib "$ENV{CBROOT}/lib";

BEGIN { 
  # test Combust::Config bug in picking up the right config file
  $ENV{CBROOTLOCAL} = $ENV{CBROOT};
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/51.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->config_file, $ENV{CBCONFIG}, 'config_file');

is($c->base_url('test'), 'http://test.local:8000', 'base_url');

