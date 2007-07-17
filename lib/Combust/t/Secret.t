use Test::More tests => 5;
use strict;

use_ok('Combust::Secret');

my $time = 8000;

my $rand = int(rand(1000000));
my $type = "test-$rand";

ok(my ($time, $secret) = Combust::Secret::get_secret(time => $time, type => $type), "get secret");
is($time, 7200, "got correct time");

is(Combust::Secret::get_secret(time => $time, type => $type), $secret, 'got the same secret twice');

ok(1);
