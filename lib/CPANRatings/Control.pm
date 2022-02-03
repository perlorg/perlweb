package CPANRatings::Control;
use Moose;
extends qw(Combust::Control Combust::Control::StaticFiles);
use LWP::Simple qw(get);
use Combust::Constant qw(OK);
use PerlOrg::Template::Filters;

my $ctemplate;

sub tt {
    my $self = shift;
    $ctemplate ||= Combust::Template->new(
        filters =>
          {'navigation_class' => [\&PerlOrg::Template::Filters::navigation_filter_factory, 1],},
        @_
    );
    return $ctemplate
      or die "Could not initialize Combust::Template object: $Template::ERROR";
}

sub post_process {
    my $self = shift;
    unless ($self->no_cache) {
        $self->request->header_out('Cache-Control', 'max-age=600');
    }
    return OK;
}

1;
