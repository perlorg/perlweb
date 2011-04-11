package CPANRatings::Control;
use strict;
use base qw(Combust::Control Combust::Control::Bitcard);
use LWP::Simple qw(get);
use CPANRatings::Model::Reviews;
use CPANRatings::Model::User;
use Digest::SHA qw(sha1_hex);
use Encode qw();
use Combust::Constant qw(OK);
use XML::RSS;

sub init {
  my $self = shift;
  $self->bc_check_login_parameters;

  #warn Data::Dumper->Dump([\%INC], [qw(INC)]);

  return OK;
}

sub bc_user_class {
  'CPANRatings::Model::User';
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
    my $text = $review->review; # substr($review->review, 0, 150);
    #$text .= " ..." if (length $text < length $review->review);
    $text = "Rating: ". $review->rating_overall . " stars\n" . $text
      if ($review->rating_overall);
    $rss->add_item(
		   title       => (!$mode || $mode eq "author" ? $review->distribution : $review->user_name),
                   link        => "$link#" . $review->id,
                   description => $text,
                   dc => {
                          creator  => $review->user_name,
                         },
                  );    
    last if ++$i == 20;
  }
  
  my $output = $rss->as_string;
  $output = Encode::encode('utf8', $output);
  $self->{_utf8} = 1;
  $output;
}

sub no_cache {
    my $self = shift;
    my $status = shift;
    $status = 1 unless defined $status;
    $self->{no_cache} = $status;
}

sub post_process {
    my $self = shift;

    if ($self->{no_cache}) {
        my $r = $self->request;

        $r->header_out('Expires', HTTP::Date::time2str( time() ));
        $r->header_out('Cache-Control', 'max-age=0,private,no-cache');
        $r->header_out('Pragma', 'no-cache');
    }
    
    return OK;
}

1;
