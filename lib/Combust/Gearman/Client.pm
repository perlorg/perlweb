package Combust::Gearman::Client;
use strict;
use Gearman::Client ();
use base qw(Gearman::Client Combust::Gearman);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->job_servers( @{ $self->_c_job_servers } );
    $self;
}

1;

