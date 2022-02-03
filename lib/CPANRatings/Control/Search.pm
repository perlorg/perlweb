package CPANRatings::Control::Search;
use strict;
use base qw(CPANRatings::Control);
use Combust::Constant qw(OK);

sub render {
    my $self     = shift;
    my $query    = $self->req_param('q');
    my $metacpan = URI->new('https://metacpan.org/search');
    $metacpan->query_form(q => $query);
    return $self->redirect($metacpan->as_string, 1);
}

1;
