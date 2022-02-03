package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use Combust::Constant qw(OK NOT_FOUND);
use URI::Escape qw(uri_escape);

sub render {
    my $self = shift;

    my ($mode, $id, $format) =
      ($self->request->path =~ m!^/([ad]|user|dist)/([^/]+?)(?:\.(html|rss|json))?$!);
    return 404 unless $mode and $id;

    $format = $self->req_param('format') || $format || 'html';
    $format = 'html' unless $format =~ /^(rss|json)$/;

    return NOT_FOUND
      unless ($mode eq 'dist' or $mode eq 'd');

    my $metacpan = 'https://metacpan.org/release/' . uri_escape($id);

    if ($format eq "html") {
        return $self->redirect($metacpan);
    }
    elsif ($format eq "rss") {
        return $self->redirect($metacpan . "/releases.rss");
    }
    elsif ($format eq "json") {
        return NOT_FOUND;
    }

    return OK, 'huh? unknown output format', 'text/plain';
}

1;
