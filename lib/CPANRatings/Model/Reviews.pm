package CPANRatings::Model::Reviews;
use base qw(CPANRatings::Model::DBI);
use strict;
use String::Truncate qw(elide);
use Combust::Util qw(escape_html);
use Class::DBI::Plugin::AbstractCount;

__PACKAGE__->table('reviews');

__PACKAGE__->columns(All => qw/id user user_name module distribution version_reviewed updated 
			review rating_overall rating_1 rating_2 rating_3 rating_4/);

__PACKAGE__->columns(TEMP => qw/_helpful_total _helpful_yes/);

__PACKAGE__->has_a('user' => 'CPANRatings::Model::User');

__PACKAGE__->add_constructor(search_review => 'distribution = ? AND module = ? AND user = ?');

__PACKAGE__->add_constructor(search_author => 'user=?', { order_by => 'updated' });

__PACKAGE__->set_sql(recent => qq{
                      SELECT __ESSENTIAL__
                      FROM __TABLE__
                      ORDER BY updated DESC
                      LIMIT 25
        });


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
  return $self->_helpful_total if defined $self->_helpful_total;
  my ($count) = $self->db_Main->selectrow_array(q[select count(*) from reviews_helpful where review=?], undef, $self->id);
  $self->_helpful_total($count);  
  $count;
}

sub helpful_yes {
  my $self = shift;
  return $self->_helpful_yes if defined $self->_helpful_yes;
  my ($count) = $self->db_Main->selectrow_array(q[select count(*) from reviews_helpful where review=? and helpful='1'], undef, $self->id);
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
