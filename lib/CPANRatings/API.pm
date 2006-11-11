package CPANRatings::API;
use strict;
use JSON;
use base qw(Combust::API);
use Data::Dumper::Simple;



my $json = JSON->new(selfconvert => 1, pretty => 1);

__PACKAGE__->setup_api(
                         'test'    => 'Test',
                         'helpful' => 'Helpful',
                        );

1;
