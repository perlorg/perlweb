package CPANRatings::Schema::ResultSet::Role::Review;
use Moose::Role;

sub recent {
    my $self  = shift;
    my %query = %{$_[0] || {}};
    my %attr  = %{$_[1] || {}};
    return $self->search(
        {%query},
        {   order_by => {-desc => 'updated'},
            rows     => 25,
            prefetch => 'user',
            %attr
        },
    );
}


1;
