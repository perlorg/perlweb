use Test::More tests => 3;
use strict;

BEGIN { 
  # TODO: only test with Apache2 if Apache2 is installed..
  $ENV{MOD_PERL} = 'mod_perl/2.0.1';
  use_ok('Combust::Constants');
}

is(Combust::Constants::NOT_FOUND, 404, 'NOT_FOUND');
is(Combust::Constants::OK, Apache2::Const::OK, 'OK');

# TODO: should test with the CGI and Apache13 class too (if available)

1;
