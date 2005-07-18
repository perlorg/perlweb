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

  my $search_type = $self->req_param('t') || 'distribution';
  $search_type = 'module' unless $search_type eq "distribution";
  
  my $results;
  $results = $search->search_distribution($query) if $search_type eq "distribution";
  $results = $search->search_module($query) if $search_type eq "module";
  
  $self->tpl_param('search' => { query   => $query,
				 results => $results,
				 search_type => $search_type,
			       });

  return OK, $self->evaluate_template($template);
}

1;


