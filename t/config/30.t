use Test::More;
use strict;

BEGIN {
  unless ($ENV{CBROOT}) {
    plan skip_all => 'ENV{CBROOT} not set';
    exit 0;
  }
  $ENV{CBCONFIG} = "$ENV{CBROOT}/t/config/30.conf";
  use_ok('Combust::Config');
}

ok(my $c = Combust::Config->new, "new");
is($c->database('test1')->{user}, "my_user1", "database->{user}"); 
is($c->db_password, 'my_password2', 'db_password (Get default password)');
is($c->db_data_source, 'dbi:driver2:database=database2;host=host2', 'db_data_source (Get default)');
# If Test::Warning is installed we should test we get the warning...
is($c->database('not_here'), $c->database('test2'), q[unconfigured database (get default, with warning)]);

done_testing();