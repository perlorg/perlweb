package CPANRatings::Control::RecentRSS;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::Reviews;
use Combust::Constant qw(OK);

sub render {
    my $self = shift;

    $self->tpl_param('header', 'Recent reviews');

    my $reviews = CPANRatings::Model::Reviews->search_recent;
    my $output = $self->as_rss($reviews);
    return OK, $output, 'application/rdf+xml';
}
 


1;
