use Test::More;
use strict;

unless (eval { require DBD::mysql } ) {
    plan skip_all => 'Could not load DBD::mysql module';
    exit 0;
}

plan tests => 21;

use_ok('Combust::Control');
use_ok('Combust::Cookies');

package Combust::Request::Test;
use base qw(Combust::Request::CGI);
$INC{'Combust/Request/Test.pm'} = 1;

sub bake_cookies {
  my $self = shift;
  #map { $_->name, $_ } @{$self->{cookies_out}};
  @{$self->{cookies_out}};
}


package main;

$ENV{COMBUST_REQUEST_CLASS} = 'Test';


ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');

my $rand = rand;
is($cookies->cookie('foo', $rand), $rand, 'set foo=$rand');
is($cookies->cookie('cpruid', 2), 2, 'set cpruid=2');
is($cookies->cookie('r', 'root'), 'root', 'set r=root');
ok(my @cookies = $cookies->bake_cookies, 'bake cookies');
my $cookie_string = $ENV{COOKIE} = join " ", map { $_->name . "=" . $_->value  } @cookies;

warn "ENV: $ENV{COOKIE}";

#warn Data::Dumper->Dump([\@cookies], [qw(cookies)]);

ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('foo'), $rand, 'is cookie the same still?');
is($cookies->cookie('r'), 'root', 'is the special cookie the same still?');

$ENV{COOKIE} = join " ", map { my $v = $_->value; $v =~ s/.$/x/; $_->name . "=" . $v } @cookies;

ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('foo'), '', 'should not get foo cookie (bad checksum)');

use Encode;
Encode::_utf8_off($cookie_string);
$ENV{COOKIE} = $cookie_string;
ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('cpruid'), '2', 'get cpruid cookie');

Encode::_utf8_on($cookie_string);
$ENV{COOKIE} = $cookie_string;
ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('cpruid'), '2', 'get cpruid cookie');
