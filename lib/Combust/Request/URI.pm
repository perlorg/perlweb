package Combust::Request::URI;
use strict;
use URI;
use overload '""' => sub { shift->[0]->path };

sub new {
    my $class = shift;
    my $uri = ref $_[0] ? $_[0] : URI->new(@_);
    return bless [ $uri ], $class;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    return shift->[0]->$method(@_);
}

1;
