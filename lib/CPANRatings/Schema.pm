package CPANRatings::Schema;
use Moose;
with 'CPANRatings::Schema::_scaffold';
use Combust::Config;

has '+dbic' => (handles => [qw(txn_do txn_scope_guard txn_begin txn_commit txn_rollback)],);

my $config = Combust::Config->new;

sub connect_args {
 (   sub { DBI->connect($config->database->{data_source},
                        $config->database->{user},
                        $config->database->{password},
                        {
                           AutoCommit        => 1,
                           RaiseError        => 1,
                           mysql_enable_utf8 => 1,
                        },
                       ) },
     {   quote_char => q{`},
         name_sep   => q{.},
         on_connect_do => [ "SET sql_mode = 'STRICT_TRANS_TABLES'",
                            "SET time_zone = 'UTC'",
                          ],
     }
 );
}

sub dbh {
    shift->dbic->storage->dbh;
}


1;
