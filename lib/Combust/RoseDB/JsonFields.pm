package Combust::RoseDB::JsonFields;

use strict;
use warnings;

use Sub::Install ();
use JSON::XS qw( encode_json decode_json );

sub import {
    my $class = shift;
    my $caller = caller;
    for my $field (@_) {
        Sub::Install::install_sub({
            code => $class->make_json_accessor($field),
            into => $caller,
            as   => $field,
        });
    }
}

sub make_json_accessor {
    my ($self, $field) = @_;
    my $priv_accessor = "_${field}";
    return sub {
        my $self = shift;

        if (@_) {
            my $h = shift;
            $self->$priv_accessor($h ? encode_json($h) : undef);
            return $h;
         }

         my $v = $self->$priv_accessor or return undef;
         return eval { decode_json($v) };
    };
}

1;
