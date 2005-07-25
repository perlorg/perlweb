package Combust::Request::Apache20;
use strict;

sub import_constants {
    my $caller = caller;
    eval "package $caller; use Apache2::Const qw(:common)";
    $@ and warn "trouble importing constants into $caller: $@" and return 0;
    return 1;
}

1;
