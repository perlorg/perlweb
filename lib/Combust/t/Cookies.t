use Test::More tests => 12;
use strict;

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
ok(my @cookies = $cookies->bake_cookies, 'bake cookies');
$ENV{COOKIE} = join " ", map { $_->name . "=" . $_->value  } @cookies;

ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('foo'), $rand, 'is cookie the same still?');

$ENV{COOKIE} = join " ", map { my $v = $_->value; $v =~ s/.$/x/; $_->name . "=" . $v } @cookies;
ok(my $request = Combust::Control->new->request, 'new request');
ok(my $cookies = Combust::Cookies->new($request), 'new cookies');
is($cookies->cookie('foo'), '', 'get cpruid cookie (bad checksum)');

