package CPANRatings::Control::ShowAll;
use strict;
use base qw(CPANRatings::Control);
use Develooper::DB qw(db_open);

sub handler ($$) {
  my ($self, $r) = @_;

  my $dbh = db_open;
  
  my $sth = $dbh->prepare('select distribution,ROUND(avg(rating_overall),1),count(*)
                           from reviews group by distribution');

  #my ($distribution, $rating, $count); 
  #$sth->bind_columns(\$distribution, \$rating, \$count);

  $sth->execute;

  print qq["distribution","rating","review_count"\n\n];

  while (my $a = $sth->fetchrow_arrayref) {
    print join(",", map { qq["$_"] } @$a), "\n";
  }

  return 200;

}

1;
