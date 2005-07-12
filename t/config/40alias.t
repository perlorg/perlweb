use Test::More qw(no_plan);
use lib "$ENV{CBROOT}/lib";
BEGIN { 
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/40.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->database('test1')->{user}, "my_user1", "database->{user}"); 
is($c->database('test2')->{user}, "my_user1", "aliased database->{user}"); 
is($c->database('test-default')->{user}, "my_user1", "defaulted to aliased database->{user}"); 

