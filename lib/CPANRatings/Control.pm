package CPANRatings::Control;
use strict;
use base qw(Combust::Control);
use Apache::Cookie;
use LWP::Simple qw(get);
use Apache::Util qw();
use CPANRatings::Model::Reviews;
use CPANRatings::Model::User;
use Encode qw();
use Apache::Constants qw(OK);

our $cookie_name = 'cpruid';

sub init {
  my $self = shift;

  # $self->req_param('id') and 
  if ($self->req_param('sig')) {
    my $bc = $self->bitcard;
    my $bc_user = eval { $bc->verify($self->r) };
    warn $@ if $@;
    unless ($bc_user) {
      warn $bc->errstr;
    }
    if ($bc_user and $bc_user->{id} and $bc_user->{username}) {
      my ($user) = CPANRatings::Model::User->search({ bitcard_id => $bc_user->{id} });
      unless ($user) {
	$user = CPANRatings::Model::User->find_or_create({ username  => $bc_user->{username} });
      }
      my $uid = $user->id;
      $user->username($bc_user->{username});
      $user->name($bc_user->{name});
      $user->bitcard_id($bc_user->{id});
      $user->update;
      $self->cookie($cookie_name, $uid);
      $self->user_info($user);
    }
  }

  $self->tpl_param('user_info', $self->user_info);

  return OK;
}

sub ___no___send_output {
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
  return 1 if $user_info and $user_info->username;
  return 0;
}

sub user_info {
  my $self = shift;

  return $self->{_user} if $self->{_user};

  if (@_) {
    return $self->{_user} = $_[0];
  }

  my $uid = $self->cookie($cookie_name) or return;
  my $user = CPANRatings::Model::User->retrieve($uid);
  return $self->{_user} = $user if $user;
  $self->cookie($cookie_name, '0');
  return;
}

sub bitcard {
  my $self = shift;
  my $bc = $self->SUPER::bitcard(@_);
  $bc->info_required('username');
  $bc;
}

sub _here_url {
  my $self = shift;
  my $here = URI->new($self->config->base_url('cpanratings')
		      . $self->r->uri 
		      . '?' . $self->r->query_string 
		     );
  $here->as_string;
}

sub login_url {
  my $self = shift;
  my $bc = $self->bitcard;
  $bc->login_url( r => $self->_here_url )
}

sub account_url {
  my $self = shift;
  my $bc = $self->bitcard;
  $bc->account_url( r => $self->_here_url )
}

sub login {
  my $self = shift;

  return $self->redirect($self->login_url);
}

sub as_rss {
  my ($self, $reviews, $mode, $id) = @_;

  require XML::RSS;
  my $rss = new XML::RSS (version => '1.0');
  my $link = "http://" . $self->config->site->{cpanratings}->{servername};
  if ($mode and $id) {
    $link .= ($mode eq "author" ? "/a/" : "/d/") . $id;
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
