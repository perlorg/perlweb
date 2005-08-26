package CPANRatings::Model::User;
use base qw(CPANRatings::Model::DBI);
use strict;

__PACKAGE__->set_up_table('review_users');
__PACKAGE__->has_many(reviews => 'CPANRatings::Model::Reviews');


1;
