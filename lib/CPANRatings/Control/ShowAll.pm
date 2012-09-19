package CPANRatings::Control::ShowAll;
use strict;
use base qw(CPANRatings::Control);
use Combust::DB qw(db_open);

sub render {
  my $self = shift;

  my $dbh = db_open;
  
  my $sth = $dbh->prepare('select distribution,ROUND(avg(rating_overall),1),count(*)
                           from reviews
                           where rating_overall > 0
                             and helpful_score >= 0
                           group by distribution');

  $sth->execute;

  my @data;

  push @data, qq["distribution","rating","review_count"\n\n];

  while (my $a = $sth->fetchrow_arrayref) {
      push @data, join(",", map { qq["$_"] } @$a), "\n";
  }

  return 200, join("", @data), 'text/plain';
}

1;
