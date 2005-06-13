package PerlOrg::Control::Search;
use strict;
use base qw(Combust::Control);
use Yahoo::Search; 
use Apache::Constants qw(OK);
use LWP::Simple qw(get);
use XML::Simple qw(XMLin);

my $yahoo = Yahoo::Search->new(AppId => 'perl.org-search');

sub handler {
  my $self = shift;

  my $query = $self->r->param('q');
  my $page  = $self->r->param('p') || 1;
  my $count = $self->r->param('n') || 15;
  my $maxcount = $yahoo->MaxCount('Doc');
  $count = $maxcount if $count > $maxcount;

  $self->param('count_per_page' => $count);
  $self->param('page_number'    => $page);

  my $start = ($page * $count) - $count;

  if ($query) {
    my $site = 'site:perl.org -site:use.perl.org';
    my $search = $yahoo->Query(Doc   => $query . " $site",
			       Start => $start,
			       Count => $count,
			      );

    if ($search->CountAvail < 10) {
      my $spell = $yahoo->Query(Spell => $query);
      $self->param(spell => $spell);
      #warn Data::Dumper->Dump([\$spell], [qw(spell)]);
    }

    #my $related= $yahoo->Query(Related => $query);
    #$self->param(related => $related);
    #warn Data::Dumper->Dump([\$related], [qw(related)]);

    $self->param(search  => $search);
    $self->param(query   => $query);
    #warn Data::Dumper->Dump([\$search], [qw(search)]);

    if ($page == 1) {
      my $xml  = get("http://search.cpan.org/search?mode=all&format=xml&n=5&query=". $query);
      my $cpan = XMLin($xml, KeepRoot => 0, KeyAttr => [], ForceArray => [qw(author dist module)]);
      for my $type (qw(module dist author)) {
	push @{$cpan->{results}}, @{$cpan->{$type}}
	  if $cpan->{$type};
      }
      $self->param('cpan', $cpan);
    }
  }

  $self->send_output(scalar $self->evaluate_template('search/results.html'));
  return OK;

}

1;
