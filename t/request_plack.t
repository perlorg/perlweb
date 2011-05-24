use Test::More;

use_ok('Combust::Request::Plack');

my $env = {
   HTTP_HOST => 'example.com',
   SCRIPT_NAME => "",
   PATH_INFO => "/some/test.html",
};

ok(my $r = Combust::Request::Plack->new($env), 'new');
isa_ok($r->uri, 'Combust::Request::URI');
is($r->path, '/some/test.html', 'path');
is($r->hostname, 'example.com', 'hostname');
is($r->uri->host, 'example.com', 'uri->host');
ok('/some/test.html' eq $r->uri, 'stringify uri');
is($r->request_url, 'http://example.com/some/test.html', 'request_url');


$env = {
   HTTP_HOST => 'example.com',
   SCRIPT_NAME => "",
   PATH_INFO => "/some/@",
};

ok($r = Combust::Request::Plack->new($env), 'new');
isa_ok($r->uri, 'Combust::Request::URI');
is($r->path, '/some/@', 'path');
is("" . $r->uri, '/some/@', 'stringify uri');

done_testing;
