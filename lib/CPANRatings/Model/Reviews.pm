package CPANRatings::Model::Reviews;
use base qw(CPANRatings::Model::DBI);
use strict;

__PACKAGE__->table('reviews');

__PACKAGE__->columns(All => qw/review_id user_id user_name module distribution version_reviewed updated 
			review rating_overall rating_1 rating_2 rating_3 rating_4/);

__PACKAGE__->columns(TEMP => qw/_helpful_total _helpful_yes/);

__PACKAGE__->add_constructor(search_review => 'distribution = ? AND module = ? AND user_id = ?');

__PACKAGE__->add_constructor(search_author => 'user_id=?', { order_by => 'updated' });

__PACKAGE__->set_sql(recent => qq{
                      SELECT __ESSENTIAL__
                      FROM __TABLE__
                      ORDER BY updated DESC
                      LIMIT 25
        });


# we have this so we can have a reviews class to call "search_foo" on in the template (how php-esqe!)
sub new {
  bless {}, shift;
}

sub add_helpful {
  my $self = shift;
  my $args = shift;
  # 2: updated, 1: insert, 0: something went wrong.
  $self->dbh->do(q[replace into reviews_helpful (review_id, user_id, helpful) values (?,?,?)], undef,
		 $self->id, $args->{user}->id, $args->{helpful}
		);
}

sub helpful_total {
  my $self = shift;
  return $self->_helpful_total if defined $self->_helpful_total;
  my ($count) = $self->db_Main->selectrow_array(q[select count(*) from reviews_helpful where review_id=?], undef, $self->id);
  $self->_helpful_total($count);  
  $count;
}

sub helpful_yes {
  my $self = shift;
  return $self->_helpful_yes if defined $self->_helpful_yes;
  my ($count) = $self->db_Main->selectrow_array(q[select count(*) from reviews_helpful where review_id=? and helpful='1'], undef, $self->id);
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
  my $review = $self->review;
  $review =~ s/^\s+//s;
  $review =~ s/\s+$//s;
  $review =~ s!\n!<br />!g;
  $review;
}


1;
