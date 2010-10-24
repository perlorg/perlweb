use Test::More;
use strict;

use_ok("Combust::Site");

my %args = (
        name   => 'foo',
        domain => 'example.com',
);

ok( my $s = Combust::Site->new(%args), 'new'
);

is($s . "", "foo", 'stringify overload');

done_testing();