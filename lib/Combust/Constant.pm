package Combust::Constant;
use strict;

use base 'Exporter';
require constant;

my %constant = (
    DONE         => -2,
    DECLINED     => -1,
    OK           => 0,
    MOVED        => 301,
    REDIRECT     => 302,
    FORBIDDEN    => 403,
    NOT_FOUND    => 404,
    SERVER_ERROR => 500,
);

our @EXPORT_OK = keys %constant;

constant->import(\%constant);

1;
