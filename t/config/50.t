use Test::More qw(no_plan);
use lib "$ENV{CBROOT}/lib";
BEGIN { 
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/50.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->base_url('test'), 'https://test.local', 'base_url');

