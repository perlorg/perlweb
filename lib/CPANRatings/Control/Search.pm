package CPANRatings::Control::Search;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::SearchCPAN;
use Apache::Constants qw(OK);

sub render {
  my $self = shift;

  my $template = 'search/search_results.html';

  my $search = CPANRatings::Model::SearchCPAN->new();
  
  my $query = $self->req_param('q');

  my $results;
  $results = $search->search_distribution($query);

  for my $r (@$results) {
      my $dist_name = $r->{distribution}->{name};
      my $reviews_count = CPANRatings::Model::Reviews->count_search_where({ distribution => $dist_name }); 
      $r->{distribution}->{reviews_count} = $reviews_count;
  }

  $self->tpl_param('search' => { query   => $query,
				 results => $results,
			       });

  return OK, $self->evaluate_template($template);
}

1;


