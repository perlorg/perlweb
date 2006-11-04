package CPANRatings::API::Test;
use strict;
use base qw(CPANRatings::API);

sub echo {
    my ($self) = @_;
    return { %{$self->args->{params}} };
}

sub _private {
    my ($self) = @_;
    return { %{$self->args->{params}} };
}

1;
