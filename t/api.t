use Test::More;
use strict;
use warnings;
use lib 't';

use_ok('CombustTest::API');

use JSON::XS;

my $data = { 'foo' => 'bar', 'a' => 1 };
ok(my ($result) = CombustTest::API->call('test/echo', { params => $data, internal => 1, json => 1 }), 'test/echo');
ok($result = decode_json($result), 'parse json');
is_deeply($result, $data, 'got the right data back');

ok(! eval { CombustTest::API->call('test/_private', { params => $data, internal => 1 })}, 'test/_private');
is($@, "Invalid method name\n");

ok(($result) = CombustTest::API->call('test', { internal => 1 }), 'test');
is_deeply($result, { foo => 'bar' }, 'index test');

ok(($result) = CombustTest::API->call('test/', { internal => 1 }), 'test/');
is_deeply($result, { foo => 'bar' }, 'index test');

done_testing();