package CPANRatings::Control::RecentRSS;
use strict;
use base qw(CPANRatings::Control);
use Combust::Constant qw(OK);

sub render {
    my $self = shift;
    return $self->redirect('https://metacpan.org/recent.rss?f=l', 1);
}


1;
