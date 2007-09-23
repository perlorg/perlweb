use Test::More tests => 8;
use strict;

use_ok('Combust::Secret');

my $time = 8000;

my $rand = int(rand(1000000));
my $type = "test-$rand";


ok(my ($time, $secret) = Combust::Secret::get_secret(time => $time, type => $type), "get secret");
is($time, 7200, "got correct time");

ok(my ($time2, $secret2) = Combust::Secret::get_secret(time => $time, type => "test-" . rand), 'get secret - different type');
isnt($secret, $secret2, 'different type, different secret');

is(Combust::Secret::get_secret(time => $time, type => $type), $secret, 'got the same secret twice');

ok(my ($time2, $secret2) = Combust::Secret::get_secret(time => time, type => "test-" . rand), 'get secret - different time');
isnt($secret, $secret2, 'different time, different secret');

