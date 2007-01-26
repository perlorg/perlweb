package Combust::Gearman::Worker;
use strict;
use Gearman::Worker ();
use base qw(Gearman::Worker Combust::Gearman);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->job_servers( @{ $self->_c_job_servers } );
    $self;
}



1;
