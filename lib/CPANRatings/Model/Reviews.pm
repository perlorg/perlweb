package CPANRatings::Model::Reviews;
use base qw(CPANRatings::Model::DBI);
use strict;

__PACKAGE__->table('reviews');

__PACKAGE__->columns(All => qw/review_id user_id user_name module distribution version_reviewed updated 
			review rating_overall rating_1 rating_2 rating_3 rating_4/);

__PACKAGE__->add_constructor(search_review => 'distribution = ? AND module = ? AND user_id = ?');

__PACKAGE__->add_constructor(search_author => 'user_id=?', { order_by => 'updated' });

__PACKAGE__->set_sql(recent => qq{
                      SELECT __ESSENTIAL__
                      FROM __TABLE__
                      ORDER BY updated DESC
                      LIMIT 10
        });



sub new {
  bless {}, shift;
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

sub review_html {
  my $self = shift;
  my $review = $self->review;
  $review =~ s/^\s+//s;
  $review =~ s/\s+$//s;
  $review =~ s!\n!<br />!g;
  $review;
}


1;
