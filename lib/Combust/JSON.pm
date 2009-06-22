
package Combust::JSON;

use strict;
use warnings;

use base qw(JSON::XS);

use Sub::Install ();

my %for_class;

# turns 'HTML::TagCloud' => '__HTML_TagCloud__'
sub _json_key {
    my $class = shift;
    $class =~ s/::/_/g;
    return '__' . $class . '__';
}

sub decode_class {
    my ($self, $class) = @_;
    my $key = $for_class{$class}{key} ||= _json_key($class);
    $self->filter_json_single_key_object($key => sub { bless shift, $class });
    $self;
}

sub encode_class {
    my ($self, $class) = @_;
    $self->allow_blessed(1);
    $self->convert_blessed(1);

    # install ::TO_JSON in $class
    if (!exists $for_class{$class}{to_json}) {
        my $key = $for_class{$class}{key} ||= _json_key($class);
        my $TO_JSON = $for_class{$class}{to_json} = sub {
            my %h = %{+shift};    # copy the object as an unblessed hash
            +{$key => \%h};       # stuff it in a single-key hash
        };
        Sub::Install::install_sub(
            {   code => $TO_JSON,
                into => $class,
                as   => 'TO_JSON'
            }
        );
    }
    $self;
}

sub handle_class {
    my ($self, $class) = @_;
    $self->encode_class($class);
    $self->decode_class($class);
    $self;
}

1;

__END__

=head1 NAME

Combust::JSON - a subclass of JSON::XS which decodes/encodes certain classes

=head1 SYNOPSIS

    use Combust::JSON ();

    $encoder = Combust::JSON->new->encode_class('HTML::TagCloud');
    $json    = $encoder->encode({ cloud => $tag_cloud }); # encodes TagCloud objects

    $decoder = Combust::JSON->new->decode_class('HTML::TagCloud');
    $data    = $decoder->decode($json); # a clone of { cloud => $tag_cloud }

=head1 DESCRIPTION

This module is a very thin wrapper (implemented as a subclass)
of JSON::XS which makes easy to define a mapping to blessed
objects of certain classes when encoding/decoding data
structures in JSON.

It does that providing two very simple methods

    $json->encode_class($class)
    $json->decode_class($class)

besides all the JSON::XS methods.

The encoding/decoding obviously depends on the coordination
of encoder and decoder, so one produces the JSON which the
other expects, allowing the specified objects to be correctly
transmitted via the intermediate JSON format. In other words,
don't expect miracles if the encoder and decoder
don't follow the same conventions to understand the
objects that matter.

The convention for the encoding/decoding a blessed
object of a given class is pretty simple. For example,
when we want "HTML::TagCloud" objects to pass by a JSON channel,
each such object gets replaced by a single-key hash ref

    { __HTML_TagCloud__ => $href }

where $href is a shallow copy of the fields of
the blessed object. So this equivalent is composed
of data structures which can be represented as JSON.
When decoding, every single-key hash is inspected
and if their only key is "__HTML_TagCloud__",
the corresponding value of pair gets blessed to
"HTML::TagCloud" and the resulting blessed reference
replaces the single-key hash in the decoded
data structure.

This was implemented with the help of hooks provided
by the JSON::XS and explained in its documentation.
The implementation of this package has a series of limitations
but on a controlled environment like the one at YellowBot
server farm, it works (so far). These hooks are
based on convert_blessed()/TO_JSON()
and filter_json_single_key_object() methods.

=head1 NOTES

1. This class has no business in loading the class it encodes/decodes.
You must do it.

2. Beware with encode_class() - it install a TO_JSON method
into the corresponding package. This is global, instead of
being limited to only the object.

3. I thought about avoiding this by using a decode() override
and a "local *CLASS::TO_JSON = sub ..." but it looks complicated,
can interact badly with the XS code, may affect performance
and introduce bugs. Research is needed for this.

4. This is currently limited to objects which are blessed hashes.

5. The implementation is a little fragile in the sense that
it looks behind the covers, into the implementation details
of the blessed object. So it is important that encoder and
decoder are synchronized at their version of the corresponding
class code (or at least are such that the corresponding
internals have not changed). Something could be done
if it was assumed the supported class code was loaded:
for example, looking at the version and using it to
build the JSON hash key.
But we keep it simple for now.


