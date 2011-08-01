package CPANRatings::API::Review;
use strict;
use base qw(CPANRatings::API::Base);

sub get {
    my $self = shift;

    use Data::Dump qw(pp);
    pp($self);

    my $distribution = $self->_required_param(qw(dist));
    my $unhelpful    =  $self->_optional_param(qw(unhelpful));

    my %query = (distribution => $distribution, 'helpful_score' => {'>', 0});

    if ($unhelpful) {
        $query{helpful_score} = { '<=', 0 };
    }
    
    my $reviews = $self->_schema->review->search( \%query );

    if ($self->_optional_param('html')) {
        return {
            html => $self->evaluate_template(
                {template => 'display/bare_list.html', params => {reviews => $reviews}}
            )
        };
    }

    return { reviews => [ $reviews->all ] };
}


1;
