use Test::More;
use strict;

unless (eval { require DBD::mysql } ) {
    plan skip_all => 'Could not load DBD::mysql module';
    exit 0;
}

use_ok('Combust::Request::Plack');
use_ok('Combust::Cookies');

package Combust::Request::Test;
use base qw(Combust::Request::Plack);
$INC{'Combust/Request/Test.pm'} = 1;

sub bake_cookies {
  my $self = shift;
  #map { $_->name, $_ } @{$self->{cookies_out}};
  @{$self->{cookies_out}};
}


package main;

my $env = { };
ok(my $request = Combust::Request::Plack->new($env), 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');

my $rand = rand;
is($cookies->cookie('foo', $rand), $rand, 'set foo=$rand');
is($cookies->cookie('cpruid', 2), 2, 'set cpruid=2');
is($cookies->cookie('r', 'root'), 'root', 'set r=root');
is($cookies->cookie('r'), 'root', 'read r=root');

ok($cookies->bake_cookies, 'bake cookies');

my $r_cookies = $request->response->cookies;

#use Data::Dump qw(pp);
#pp(\$r_cookies);

my $cookie_string = join " ", map { $_ . "=" . $r_cookies->{$_}->{value}  } sort keys %$r_cookies;
$env->{HTTP_COOKIE} = $cookie_string;

ok($request = Combust::Request::Plack->new($env), 'new request');
ok($cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('foo'), $rand, 'is cookie the same still?');
is($cookies->cookie('r'), 'root', 'is the special cookie the same still?');

{
    # corrupt the cookies a bit
    my $env_corrupt = { %$env };
    $env_corrupt->{HTTP_COOKIE} = join " ", map {
        my $v = $r_cookies->{$_}->{value};
        $v =~ s/.$/x/;
        $_ . "=" . $v
    } sort keys %$r_cookies;

    ok($request = Combust::Request::Plack->new($env_corrupt), 'new request');
    ok($cookies = Combust::Cookies->new($request),    'new cookies');
    is($cookies->cookie('foo'), '', 'should not get foo cookie (bad checksum)');
}

use Encode;
Encode::_utf8_off($cookie_string);
$env->{HTTP_COOKIE} = $cookie_string;
ok($request = Combust::Request::Plack->new($env), 'new request');
ok($cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('cpruid'), '2', 'get cpruid cookie');

Encode::_utf8_on($cookie_string);
$env->{HTTP_COOKIE} = $cookie_string;
ok($request = Combust::Request::Plack->new($env), 'new request');
ok($cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('cpruid'), '2', 'get cpruid cookie');

done_testing();