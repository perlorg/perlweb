package CPANRatings::API::Base;
use Moose;
extends 'Combust::API::Base';
use CPANRatings::Schema;

# TODO: probably should just have the controller pass in the schema
# object
has _schema => (
    isa => 'CPANRatings::Schema',
    is  => 'ro',
    lazy_build => 1,
);

sub _build__schema {
    return CPANRatings::Schema->new;
}

1;
