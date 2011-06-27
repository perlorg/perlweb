package PerlOrg::Control::CSS;
use Moose;
extends 'PerlOrg::Control', 'Combust::Control::Basic';

#    $css = minify($css) unless $devel and !$self->req_param('minify');

sub render {
    my $self = shift;

    $self->force_template_processing(1);
    $self->fixup_static_version;

    my @r = $self->SUPER::render(@_);

    return @r;
}


1;
