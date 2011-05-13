use strict;
use lib 'lib', 't/app/trivial/lib';
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/app/trivial/combust.conf";
  $ENV{CBROOTLOCAL} = "$ENV{CBROOT}/t/app/trivial/";
}

use_ok('Trivial::App');
system("$ENV{CBROOT}/bin/make_configs");
ok(my $app = Trivial::App->new, 'new app');

   test_psgi
     app => $app->reference,
     client => sub {
       my $cb = shift;
       my $res = $cb->(GET "/three.html");
       like $res->content, qr/Hello World/;

       $res = $cb->(GET "/three");
       like $res->content, qr/Hello Static/;

       $res = $cb->(GET "/two/redirect");
       like $res->content, qr/The document has moved/;

   };


done_testing();