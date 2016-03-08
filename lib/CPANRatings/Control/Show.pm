package CPANRatings::Control::Show;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::SearchCPAN qw();
use Combust::Constant qw(OK NOT_FOUND);

sub render {
    my $self = shift;

    my ( $mode, $id, $format ) =
      ( $self->request->path =~ m!^/([ad]|user|dist)/([^/]+?)(?:\.(html|rss|json))?$! );
    return 404 unless $mode and $id;

    $format = $self->req_param('format') || $format || 'html';
    $format = 'html' unless $format =~ /^(rss|json)$/;

    if ( $mode eq 'a' ) {
        my $user = $self->schema->user->find($id) or return NOT_FOUND;
        return $self->redirect(
            "/user/" . $user->username . ( $format ne "html" ? ".$format" : '' ) );
    }
    elsif ( $mode eq 'd' ) {
        return $self->redirect( "/dist/$id" . ( $format ne "html" ? ".$format" : '' ) );
    }

    my $mode_element = $id;

    my $user;
    if ( $mode eq 'user' ) {
        ($user) = $self->schema->user->search( { username => $id } ) or return NOT_FOUND;
        $id           = $user->id;
        $mode_element = $user->username;
    }

    $self->tpl_param( 'this_url' => join( "/", "", $mode, $mode_element ) );

    $mode = "distribution" if $mode eq "dist";

    my $template = 'display/list.html';

    $self->tpl_param( 'mode' => $mode );
    $self->tpl_param( 'header' => "$id reviews" ) if $mode eq "distribution";

    if ( $mode eq "user" ) {
        $self->tpl_param( 'header' => "Reviews by " . $user->name );

        my $reviews = $self->schema->review->search(
            {   $mode  => $id,
                status => 'active',
            },
            { order_by => { -desc => 'updated' } }
        );

        $self->tpl_param( 'reviews' => $reviews );


    }
    else {
        unless ( CPANRatings::Model::SearchCPAN->valid_distribution($id) ) {
            return NOT_FOUND;
        }
        my ($first_review) =
          $self->schema->review->search( { distribution => $id }, { rows => 1 } );
        $self->tpl_param( 'distribution' => $first_review->distribution ) if $first_review;
        $self->tpl_param( 'distribution' => $id ) unless $first_review;

        my $reviews = $self->schema->review->search(
            {   $mode  => $id,
                status => 'active',
                ( $format eq 'json' ? () : ( helpful_score => { '>', 0 } ) ),
            },
            { order_by => { -desc => 'updated' } }
        );

        my $unhelpful_count = $self->schema->review->count(
            {   $mode  => $id,
                status => 'active',
                helpful_score => { '<=', 0 }
            },
        );
        $self->tpl_param( 'reviews' => $reviews );

        $self->tpl_param( 'unhelpful_count' => $unhelpful_count );


    }

    if ( $format eq "html" ) {
        return OK, $self->evaluate_template($template), 'text/html';
    }
    elsif ( $format eq "rss" ) {
        my $output = $self->as_rss( $self->tpl_param('reviews'), $mode, $mode_element );
        return OK, $output, 'application/rss+xml';
    }
    elsif ( $format eq "json" ) {
        my $output = $self->as_json( $self->tpl_param('reviews'), $mode, $mode_element );
        return OK, $output, 'application/json';
    }

    return OK, 'huh? unknown output format', 'text/plain';
}

1;
