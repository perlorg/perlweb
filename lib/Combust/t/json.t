
use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok 'Combust::JSON' }

### setup

use HTML::TagCloud;

my @tags = (
    {tag => 'foo',       url => '/tag/foo',       count => '1'},
    {tag => 'food',      url => '/tag/food',      count => '7'},
    {tag => 'ice cream', url => '/tag/ice+cream', count => '5'},
);

sub cloud {
    my $cloud = HTML::TagCloud->new;
    for my $t (@tags) {
        $cloud->add($t->{tag}, $t->{url}, $t->{count});
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
    ok($json_data, "data encoded");
}

{
    my $decoder = Combust::JSON->new->decode_class('HTML::TagCloud');
    my $decoded = $decoder->decode($json_data);
    is_deeply($decoded, $data, "data (including blessed object) decodes ok");
}


