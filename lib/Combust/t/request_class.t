use Test::More tests => 9;
use strict;

use_ok('Combust::Control');

is(Combust::Control->pick_request_class, 'Combust::Request::CGI');
$ENV{MOD_PERL} = 'mod_perl/1.29';
is(Combust::Control->pick_request_class, 'Combust::Request::Apache13');

delete $ENV{MOD_PERL};

ok(my $request = Combust::Control->new->request, 'new request');
is($request->content_type('text/plain'), 'text/plain', 'set content_type');
is($request->content_type, 'text/plain', 'get content_type');

is($request->notes('foobar', 'blah'), 'blah', 'set note');
is($request->notes('foobar'), 'blah', 'get note');

$ENV{COOKIE} = 'p=2/LRp/~1121917140/~cpruid/~2/BCFFF286';
is($request->cookie('p'), '2/LRp/~1121917140/~cpruid/~2/BCFFF286', 'get cookie');


1;




