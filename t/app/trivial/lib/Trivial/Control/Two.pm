package Trivial::Control::Two;
use strict;
use base 'Trivial::Control';
use Combust::Constant qw(OK);

sub render {
    my $self = shift;
    $self->tpl_param('now', scalar localtime );
    return OK, $self->evaluate_template('two');
}

1;
