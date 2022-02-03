package CPANRatings::Control::Basic;
use strict;
use base qw(CPANRatings::Control Combust::Control::Basic);

sub render {
    my $self = shift;

    if ($self->request->uri =~ m!^/(index\.html)?$!) {
        return $self->redirect('https://metacpan.org/', 1);
    }

    $self->SUPER::render(@_);
}

1;
