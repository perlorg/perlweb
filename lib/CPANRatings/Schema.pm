package CPANRatings::Schema;
use Moose;
with 'CPANRatings::Schema::_scaffold';
use Combust::Config;
use DBI;

has '+dbic' => (handles => [qw(txn_do txn_scope_guard txn_begin txn_commit txn_rollback)],);

my $config = Combust::Config->new;

sub connect_args {
    return (
        sub {
            DBI->connect(
                $config->database->{data_source},
                $config->database->{user},
                $config->database->{password},
                {   AutoCommit        => 1,
                    RaiseError        => 1,
                    mysql_enable_utf8 => 1,
                },
            );

        },
        {   on_connect_do => [
                "SET sql_mode = 'STRICT_TRANS_TABLES'",
                "SET time_zone = 'UTC'",
#                "SET names utf8",
#                "SET character set utf8",
            ],
        }
    );
}

sub dbh {
    shift->dbic->storage->dbh;
}


1;
