use Test::More qw(no_plan);
use lib "$ENV{CBROOT}/lib";
BEGIN { 
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/51.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->base_url('test'), 'http://test.local:8000', 'base_url');

