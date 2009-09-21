use Test::More qw(no_plan);
use strict;
use warnings;

use_ok('CPANRatings::API');

use JSON::XS;

my $data = { 'foo' => 'bar', 'a' => 1 };
ok(my ($result) = CPANRatings::API->call('test/echo', { params => $data, internal => 1, json => 1 }), 'test/echo');
ok($result = decode_json($result), 'parse json');
is_deeply($result, $data, 'got the right data back');

ok(! eval { CPANRatings::API->call('test/_private', { params => $data, internal => 1 })}, 'test/_private');
is($@, "Invalid method name\n");

