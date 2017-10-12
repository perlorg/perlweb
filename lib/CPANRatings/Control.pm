package CPANRatings::Control;
use Moose;
extends qw(Combust::Control Combust::Control::Bitcard::DBIC Combust::Control::StaticFiles);
use LWP::Simple qw(get);
use CPANRatings::Schema;
use CPANRatings::Model::SearchCPAN;
use Digest::SHA qw(sha1_hex);
use Encode qw();
use Combust::Constant qw(OK);
use PerlOrg::Template::Filters;
use XML::RSS;
use JSON;
use DateTime::Format::ISO8601;
use DateTime::Format::W3CDTF;
use DateTime;

has schema => (
    isa => 'CPANRatings::Schema',
    is  => 'ro',
    lazy_build => 1,
);

sub _build_schema {
    return CPANRatings::Schema->new;
}

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

sub init {
  my $self = shift;
  $self->bc_check_login_parameters;

  #warn Data::Dumper->Dump([\%INC], [qw(INC)]);

  return OK;
}

sub bc_user_class {
   shift->schema->user;
}

# old code here
sub user_info { shift->user(@_) }

sub bc_info_required {
  'username'
}

sub user_auth_token {
    my $self = shift;
    return $self->{_user_auth_token} if $self->{_user_auth_token};
    $self->cookie('uq', sha1_hex(time . rand)) unless $self->cookie('uq');
    return $self->{_user_auth_token} = _calc_auth_token( $self->cookie('uq') );
}

sub _calc_auth_token {
    my $cookie = shift;
    return '1-' . sha1_hex('8wae4ko -  this is very secret!' . $cookie);
}

sub as_json {
    my ($self, $reviews, $mode, $id) = @_;

    my $data = {
        $mode => $id,
        reviews => [],
    };

    # default to one year being outdated...
    my $outdated = DateTime->now->subtract( years => 1 );

    if ( $mode eq 'distribution' ) {
        # go by date of latest version
        my $search = CPANRatings::Model::SearchCPAN->new;
        if ( my $releases = $search->get_releases( $id ) ) {
            my $last_release_date = DateTime::Format::ISO8601->parse_datetime(
                $releases->[0]->{released}
            );

            # if last release date was within the last year, then use the last
            # release date as the cutoff point
            $outdated = $last_release_date
                if $last_release_date > $outdated;
        }
    }

    my %sum;

    while (my $review = $reviews->next) {

        my $is_outdated = ( $review->updated < $outdated ) ? 1 : 0;
        my $review_for_data = {
            review   => $review->review,
            version  => $review->version_reviewed,
            status   => $review->status,
            rating   => int( $review->rating_overall ),
            user     => $review->user_name,
            date     => $review->updated->iso8601,
            outdated => $is_outdated ? JSON::true : JSON::false,
            helpful  => $review->helpful_score > 0 ? JSON::true : JSON::false,
        };

        $sum{all}    += $review->helpful_score > 0 ? int( $review->rating_overall ) : 0;
        $sum{recent} += ! $is_outdated && $review->helpful_score > 0
            ? int( $review->rating_overall ) : 0;

        push( @{ $data->{reviews} },$review_for_data );
    }

    if ( my @reviews = @{ $data->{reviews} } ) {

        my @all     = grep { $_->{helpful} } @reviews;
        my @recent  = grep { $_->{helpful} && !$_->{outdated} } @reviews;

        $data->{ratings} = {
            all    => @all    ? sprintf( "%.1f",$sum{all} / @all ) : undef,
            recent => @recent ? sprintf( "%.1f",$sum{recent} / @recent ) : undef,
        };
    } else {
        $data->{ratings} = {};
    }

    return JSON->new->utf8->encode( $data );
}

sub as_rss {
  my ($self, $reviews, $mode, $id) = @_;


  my $rss = XML::RSS->new(version => '1.0');
  my $link = $self->config->base_url('cpanratings');
  if ($mode and $id) {
      $link .= ($mode eq "author" ? "/user/" : "/dist/") . $id;
  }
  else {
      $link .= '/';
  }

  $rss->channel(
                title        => "CPAN Ratings: " . $self->tpl_param('header'),
                link         => $link, 
                description  => "CPAN Ratings: " . $self->tpl_param('header'),
                dc => {
                       date       => '2000-08-23T07:00+00:00',
                       subject    => "Perl",
                       creator    => 'ask@perl.org',
                       publisher  => 'ask@perl.org',
                       language   => 'en-us',
                      },
                syn => {
                        updatePeriod     => "daily",
                        updateFrequency  => "1",
                        updateBase       => "1901-01-01T00:00+00:00",
                       },
               );

  my $i; 
  while (my $review = $reviews->next) {
    my $text = "<p>@{[$review->review_html]}</p>";
    $text = "<p>Rating: @{[$review->rating_overall]} stars</p>$text"
      if ($review->rating_overall);
    $rss->add_item(
		   title       => (!$mode || $mode eq "author" ? $review->distribution : $review->user_name),
                   link        => "$link#" . $review->id,
                   description => $text,
                   dc => {
                          creator  => $review->user_name,
                          date  => DateTime::Format::W3CDTF->new->format_datetime( $review->updated ),
                         },
                  );    
    last if ++$i == 20;
  }
  
  my $output = $rss->as_string;
  $output = Encode::encode('utf8', $output);
  $self->{_utf8} = 1;
  $output;
}

sub post_process {
    my $self = shift;
    unless ($self->no_cache) {
        $self->request->header_out('Cache-Control', 'max-age=600');
    }
    return OK;
}

1;
