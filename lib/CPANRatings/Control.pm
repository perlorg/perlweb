package CPANRatings::Control;
use Combust::Control;
@ISA = qw(Combust::Control);
use strict;
use Apache::Cookie;
use LWP::Simple qw(get);
use Combust::Cache;
use Apache::Util qw();
use CPANRatings::Model::Reviews;
use Encode qw();

sub super ($$) {
 
  my $self = shift->SUPER::_init(@_);

  $self->param('user_info', $self->user_info);

  $self->SUPER::super(@_);
}

sub send_output {
  my $class   = shift;
  my $routput = shift;

  $routput = $$routput if ref $routput;

  return $class->SUPER::send_output(\$routput, @_)
    if (ref $routput eq "GLOB" or $class->{utf8});

#  binmode STDOUT, ':utf8';

  my $str = Encode::encode('iso-8859-1', $routput, Encode::FB_HTMLCREF);

  $class->SUPER::send_output(\$str, @_);
}

sub is_logged_in {
  my $self = shift;
  my $user_info = $self->user_info;
  return 1 if $user_info and $user_info->{user_id};
  return 0;
}

sub user_info {
  my $self = shift;
  my $cookies = Apache::Cookie->new($self->{r})->parse || {};
  return {} unless $cookies->{ducttape};
  my $cookie = $cookies->{ducttape}->value;

  my $cache = Combust::Cache->new( type => 'auth' );

  my $data = $cache->fetch(id => "ducttape=$cookie");
  return $data->{data} if $data;

  warn "has ducttape cookie: ", $cookie;
  $cookie =~ s/[^a-z0-9]//g;
  $data = get("http://auth.perl.org/dbgw/cookie_validate?sid=$cookie");
  warn "Data: $data";
  return {} unless $data =~ s/^OK\n//s;
  my $user_data = +{ map { split /\t/ } split /\n/, $data };
  #warn Data::Dumper->Dump([\$user_data, \@x], [qw(user_data x)]);

  $cache->store(data => $user_data, expires => 5*60 );

  $user_data;
}

sub login {
  my $self = shift;
  my $r = $self->r;
  return $self->redirect($r,
			 "http://auth.perl.org/login?redirect=http://"
			 . $self->config->site->{cpanratings}->{servername}
			 . $self->r->uri 
			 . ($r->query_string ? Apache::Util::escape_uri("?" . $r->query_string) : '')
			); 
}

sub as_rss {
  my ($self, $r, $reviews, $mode, $id) = @_;

  require XML::RSS;
  my $rss = new XML::RSS (version => '1.0');
  my $link = "http://" . $self->config->site->{cpanratings}->{servername};
  if ($mode and $id) {
    $link .= ($mode eq "author" ? "/a/" : "/d/") . $id;
  }

  $rss->channel(
                title        => "CPAN Ratings: " . $self->param('header'),
                link         => $link, 
                description  => "CPAN Ratings: " . $self->param('header'),
                dc => {
                       date       => '2000-08-23T07:00+00:00',
                       subject    => "Perl",
                       creator    => 'ask@perl.org',
                       publisher  => 'ask@perl.org',
                       rights     => 'Copyright 2004, The Perl Foundation',
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
    my $text = substr($review->review, 0, 150);
    $text .= " ..." if (length $text < length $review->review);
    $text = "Rating: ". $review->rating_overall . " stars\n" . $text
      if ($review->rating_overall);
    $rss->add_item(
		   title       => (!$mode || $mode eq "author" ? $review->distribution : $review->user_name),
                   link        => "$link#" . $review->review_id,
                   description => $text,
                   dc => {
                          creator  => $review->user_name,
                         },
                  );    
    last if ++$i == 10;
  }
  
  my $output = $rss->as_string;
  $output = Encode::encode('utf8', $output);
  $self->{_utf8} = 1;
  $output;
}

1;
