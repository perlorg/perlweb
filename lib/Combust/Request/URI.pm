package Combust::Request::URI;
use strict;
use URI;
use overload
  '""'  => sub { shift->[1] },
  'cmp' => sub { shift->[1] cmp shift }
  ;

sub new {
    my $class = shift;
    my $uri = ref $_[0] ? $_[0] : URI->new(@_);
    return bless [ $uri, $_[1] ], $class;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    return shift->[0]->$method(@_);
}

1;
