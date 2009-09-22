use Test::More tests => 16;
use strict;
use warnings;
use lib 't';

use_ok('CombustTest::API');

use JSON::XS;

my $data = { 'foo' => 'bar', 'a' => 1 };
ok(my ($result) = CombustTest::API->call('test/echo', { params => $data, internal => 1, json => 1 }), 'test/echo (json)');
ok($result = decode_json($result), 'parse json');
is_deeply($result, $data, 'got the right data back');

ok(($result) = CombustTest::API->call('test/echo/', { params => $data, internal => 1  }), 'test/echo (no json)');
is_deeply($result, $data, 'got the right data back');

ok(! eval { CombustTest::API->call('test/_private', { params => $data, internal => 1 })}, 'test/_private');
is($@, "Invalid method name\n", 'got correct error');

ok(! eval { CombustTest::API->call('test/1xx', { params => $data, internal => 1 })}, 'test/1xx');
is($@, "Invalid method name\n", 'got correct error');

ok(! eval { CombustTest::API->call('test/not_here', { params => $data, internal => 1 })}, 'test/1xx');
is($@, qq[No method "not_here"\n], 'got correct error');

ok(($result) = CombustTest::API->call('test', { internal => 1 }), 'test');
is_deeply($result, { foo => 'bar' }, 'index test');

ok(($result) = CombustTest::API->call('test/', { internal => 1 }), 'test/');
is_deeply($result, { foo => 'bar' }, 'index test');

