package CPANRatings::API::Helpful;
use strict;
use base qw(CPANRatings::API::Base);

sub vote {
  my $self = shift;

  my ($review_id, $vote) = $self->_required_param(qw(review_id vote));

  $review_id = ''  unless $review_id =~ m/^\d+$/;

  $vote =~ m/^(yes|no)$/ or return { error => 'Bad vote parameter' };

  my $user = $self->user or return { error => 'You must be logged in to vote' };

  my $review = $self->_schema->review->find($review_id)
      or return { error => 'There was an error processing your request. Please try again later.' };

  return { error => 'You are not allowed to vote on your own review.' }
    if $review->user->id == $user->id;

  my $updated = $review->add_helpful({ user => $user, helpful => $vote eq 'yes' ? 1 : 0 });

  return { error => 'There was an error processing your request. Please try again later.' }
    unless $updated;

  return { message => ($updated == 2
                       ? "We'll update your vote." 
                       : 'Your vote will be counted within a couple of hours.'
                       )
           }
}


1;
