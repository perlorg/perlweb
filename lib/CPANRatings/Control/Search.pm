package CPANRatings::Control::Search;
use strict;
use base qw(CPANRatings::Control);
use CPANRatings::Model::SearchCPAN;

sub handler ($$) {
  my ($self, $r) = @_;

  my $template = 'search/search_results.html';

  my $search = CPANRatings::Model::SearchCPAN->new();

  my $query = $r->param('q');

  warn "QUERY1: $query";

  my $search_type = $r->param('t') || 'distribution';
  $search_type = 'module' unless $search_type eq "distribution";

  my $results;
  $results = $search->search_distribution($query) if $search_type eq "distribution";
  $results = $search->search_module($query) if $search_type eq "module";
  
  $self->param('search' => { query   => $query,
			     results => $results,
			     search_type => $search_type,
			   });

  my $output;
  $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);
  $r->update_mtime(time);
  $self->send_output($r, \$output);
}

1;


