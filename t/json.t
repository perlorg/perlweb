
use strict;
use warnings;

use Test::More tests => 6;
use Test::Deep;

BEGIN { use_ok 'Combust::JSON' }

### setup

use HTML::TagCloud;

my @tags = (
    { tag => 'foo',       url => '/tag/foo',       count => '1' },
    { tag => 'food',      url => '/tag/food',      count => '7' },
    { tag => 'ice cream', url => '/tag/ice+cream', count => '5' },
);

sub cloud {
    my $cloud = HTML::TagCloud->new;
    for my $t (@tags) {
        $cloud->add( $t->{tag}, $t->{url}, $t->{count} );
    }
    return $cloud;
}

my $cloud = cloud;
my $data  = {
    name      => 'Foo Inc.',
    score     => 30,
    tag_cloud => $cloud,
};

### tests

my $json_data;

{
    my $encoder = Combust::JSON->new->encode_class('HTML::TagCloud');
    $json_data = $encoder->encode($data);
    ok( $json_data, "data encoded" );
}

{
    my $decoder = Combust::JSON->new->decode_class('HTML::TagCloud');
    my $decoded = $decoder->decode($json_data);
    is_deeply( $decoded, $data, "data (including blessed object) decodes ok" );
}

package My::Object;

my %SUBS = (
    1 => sub {1},
    2 => sub {2},
);

sub new {
    my ( $class, $num ) = @_;
    return bless { num => $num, sub => $SUBS{$num} }, $class;
}

sub JSON_freeze {
    my $self         = shift;
    my $to_serialize = {%$self};
    delete $to_serialize->{sub};    # JSON can't encode CODE refs
    $to_serialize;
}

sub JSON_thaw {
    my $self = bless shift;
    $self->{sub} = $SUBS{ $self->{num} };
    $self;
}

# NOTE. JSON_freeze and JSON_thaw should be such
# that
#       $obj
# and
#       My::Object->can('JSON_thaw')->( $obj->JSON_freeze )
# are equivalent


package main;

{
    my $obj     = My::Object->new(2);
    my $encoder = Combust::JSON->new->encode_class('My::Object');
    my $js      = $encoder->encode($obj);
    ok( $js, "object encoded" );
    my $decoder = Combust::JSON->new->decode_class('My::Object');
    my $obj2    = $decoder->decode($js);
    ok( $obj2, "object decoded" );
    cmp_deeply( $obj, $obj2, "object successfully restored" );
}
