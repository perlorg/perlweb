package Combust::Control::Bitcard::RDBO;
use strict;
use base qw(Combust::Control::Bitcard);

sub _setup_user {
    my ($self, $bc_user) = @_;
    my $user;
    if ($self->bc_user_class->can('username') and $bc_user->{username}) {
        ($user) = $self->bc_user_class->fetch( username => $bc_user->{username} );
    }
    $user = $self->bc_user_class->fetch_or_create(bitcard_id => $bc_user->{id}) unless $user;
    for my $m (qw(username email name)) {
        next unless $user->can($m);
        $user->$m($bc_user->{$m});
    }
    $user->bitcard_id($bc_user->{id});
    $user->save;
    return $user;
}

1;
