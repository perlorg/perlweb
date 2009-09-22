use Test::More;
use strict;

unless (eval { require DBD::mysql } ) {
    plan skip_all => 'Could not load DBD::mysql module';
    exit 0;
}

plan tests => 8;

use_ok('Combust::Secret');

my $time = 8000;

my $rand = int(rand(1000000));
my $type = "test-$rand";


ok(($time, my $secret) = Combust::Secret::get_secret(time => $time, type => $type), "get secret");
is($time, 7200, "got correct time");

ok(my ($time2, $secret2) = Combust::Secret::get_secret(time => $time, type => "test-" . rand), 'get secret - different type');
isnt($secret, $secret2, 'different type, different secret');

is(Combust::Secret::get_secret(time => $time, type => $type), $secret, 'got the same secret twice');

ok(($time2, $secret2) = Combust::Secret::get_secret(time => time, type => "test-" . rand), 'get secret - different time');
isnt($secret, $secret2, 'different time, different secret');

