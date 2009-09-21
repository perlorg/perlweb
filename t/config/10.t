use Test::More;
use strict;

BEGIN { 
  unless ($ENV{CBROOT}) {
    plan skip_all => 'ENV{CBROOT} not set';
    exit 0;
  }
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/10.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
ok(my $c2 = Combust::Config->new, "new");
is($c, $c2, "get the same config object twice");


is($c->servername, 'combust.local', 'servername');
is($c->port, 8225, 'default port');
is($c->site->{test}->{servername}, 'test.local', 'site servername');
is($c->site->{test}->{siteadmin},  'ask@example.com', 'site siteadmin');

is($c->base_url('test'), 'http://test.local', 'base_url');

done_testing();
