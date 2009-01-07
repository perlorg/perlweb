package Combust::RoseDB::Transaction;

sub new {
    my ($pkg, $db) = @_;
    $db->begin_work or return;
    bless \$db;
}

sub DESTROY {
    my $db = ${$_[0]};
    local $@;
    if ($db->in_transaction) {
        $db->combust_model->flush_caches;    # elements in caches may not be in database
        eval { $db->disconnect(force => 1) }
          unless eval { defined $db->rollback };
    }
}

1;
