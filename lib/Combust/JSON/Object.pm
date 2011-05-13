
package Combust::JSON::Object;

use strict;
use warnings;

use Sub::Install ();

sub import {
    my $self   = shift;
    my $caller = caller;
    $self->inject_into($caller);
}

sub inject_into {
    my ( $self, $class ) = @_;
    return if $class->isa($self);

    # Inherit from this package
    {
        no strict 'refs';
        push @{"${class}::ISA"}, __PACKAGE__;
    }

    return if $class->can('JSON_key');

    # Install a JSON_key sub
    my $key = _json_key($class);
    Sub::Install::install_sub(
        {   code => sub () {$key},
            into => $class,
            as   => 'JSON_key',
        }
    );
}

# turns 'HTML::TagCloud' => '__HTML_TagCloud__'
sub _json_key {
    my $class = shift;
    $class =~ s/::/_/g;
    return '__' . $class . '__';
}

sub TO_JSON {
    my $self   = shift;
    my $key    = $self->JSON_key;
    my $frozen = $self->JSON_freeze;
    $frozen->{__class__} ||= ref $self;
    return +{ $key => $frozen };
}

sub JSON_freeze {
    my %h = %{ +shift };
    return \%h;
}

sub JSON_thaw {
    my $obj   = shift;
    my $class = delete $obj->{__class__};
    bless $obj, $class;
}

1;

__END__

=head1 SYNOPSIS

    package SomeObject;
    use Combust::JSON::Object;

    # or
    use Combust::JSON::Object ();
    Combust::JSON::Object->inject_into('SomeObject);


