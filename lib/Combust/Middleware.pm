package Combust::Middleware;
use Moose;
extends 'Combust::Base';

has 'app' => (
    is  => 'rw',
    isa => 'CodeRef',
    required => 0,
);

sub wrap {
    my ($self, $app, @args) = @_;

    warn "APP REF: ", ref $app;

    if (ref $self) {
        $self->app($app);
    } else {
        $self = $self->new({ app => $app, @args });
    }
    return sub { $self->call(@_) }
}



1;
