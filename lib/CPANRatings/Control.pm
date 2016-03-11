package CPANRatings::Control;
use Moose;
extends qw(Combust::Control Combust::Control::Bitcard::DBIC Combust::Control::StaticFiles);
use LWP::Simple qw(get);
use CPANRatings::Schema;
use Digest::SHA qw(sha1_hex);
use Encode qw();
use Combust::Constant qw(OK);
use PerlOrg::Template::Filters;
use XML::RSS;
use DateTime::Format::W3CDTF;

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
    return $ctemplate ||= Combust::Template->new(
        filters =>
          {'navigation_class' => [\&PerlOrg::Template::Filters::navigation_filter_factory, 1],},
        @_
    ) or die "Could not initialize Combust::Template object: $Template::ERROR";
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
