package RRE;
use strict;
use Develooper::DB;

sub get_category_id {
  my ($name, $create) = @_;

  my $dbh = db_open;

  my ($id) = $dbh->selectrow_array(q[select category_id from rre_categories 
                                     WHERE category_name=?], {},
                                   $name
                                  );

  if (!$id and $create) {
    $dbh->do(q[insert into rre_categories (category_name) VALUES (?)], {}, $name);
    $id = $dbh->{mysql_insertid};
  }

  return $id;
}

1;
