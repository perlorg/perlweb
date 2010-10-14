package Combust::Control::StaticFiles;
use strict;
use Combust::StaticFiles ();

my %cache;

sub __static {
    my $self = shift;
    return $cache{ $self->site } ||= Combust::StaticFiles->new( site => $self->site );
}

sub static_url {
    return shift->__static->static_url(@_);
}

sub static_group {
    return shift->__static->static_group(@_);
}

1;
