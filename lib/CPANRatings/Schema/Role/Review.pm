package CPANRatings::Schema::Role::Review;
use Moose::Role;
use String::Truncate qw(elide);
use Combust::Util qw(escape_html);
use namespace::clean;

has '_helpful_total' => (
    is      => 'rw',
    isa     => 'Int',
);

has '_helpful_yes' => (
    is      => 'rw',
    isa     => 'Int',
);

sub user_name {
    my $self = shift;
    $self->user->name || $self->user->username;
}

# temporary until everything is changed to use DBIx::Class methods
sub dbh {
    shift->result_source->storage->dbh;
}

sub add_helpful {
  my $self = shift;
  my $args = shift;
  # 2: updated, 1: insert, 0: something went wrong.
  $self->dbh->do(q[replace into reviews_helpful (review, user, helpful) values (?,?,?)], undef,
		 $self->id, $args->{user}->id, $args->{helpful}
		);
}

sub helpful_total {
  my $self = shift;
  # use Data::Dump qw(pp);
  # warn "SELF: ", pp($self);
  return $self->_helpful_total if defined $self->_helpful_total;
  my ($count) = $self->dbh->selectrow_array(q[select count(*) from reviews_helpful where review=?], undef, $self->id);
  $self->_helpful_total($count);  
  $count;
}

sub helpful_yes {
  my $self = shift;
  return $self->_helpful_yes if defined $self->_helpful_yes;
  my ($count) = $self->dbh->selectrow_array(q[select count(*) from reviews_helpful where review=? and helpful='1'], undef, $self->id);
  $self->_helpful_yes($count); 
  $count;
}


sub checked_rating {
  my $self = shift;
  my $checked = {};
  for my $f (qw(rating_overall rating_1 rating_2 rating_3 rating_4)) {
    my $rating = $self->$f;
    $rating = 0 unless $rating and $rating =~ m/^[1-5]$/;
    $checked->{$f} = { $rating => "checked" };
  }
  $checked;
}

sub has_detail_ratings {
  my $self = shift;
  for my $i (1..4) {
    my $m = "rating_$i";
    return 1 if $self->$m;
  }
  return 0;
}

sub review_html {
  my $self = shift;
  convert_to_html( $self->review );
}

sub convert_to_html {
    my $str = shift;

    return "" unless defined $str and $str ne '';
    #$str =~ s@<.+?>@ @gs;

    $str = escape_html($str);

    $str
      =~ s!(https?://(.+?))([,.;-]+\s|\s|$)!"<a href=\"$1\" rel=\"nofollow\">"._shorten_text($2)."</a>$3"!egi;
    $str =~ s!\n\s*[\n\s]+!<br><br>!g;
    $str =~ s!\n!<br>\n!g;

    $str;
}

sub _shorten_text {
    my $linktext = shift;
    my $length   = shift || 40;
    return elide($linktext, $length);
}


1;

