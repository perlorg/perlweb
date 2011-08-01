package CPANRatings::API;
use strict;
use base qw(Combust::API);

__PACKAGE__->setup_api(
                       'test'    => 'Test',
                       'helpful' => 'Helpful',
                       'review'  => 'Review',
                      );

1;
