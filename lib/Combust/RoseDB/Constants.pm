package Combust::RoseDB::Constants;

use base qw(Exporter);

use constant DB_DOWN    => 0;
use constant DB_BOUNCED => 1;
use constant DB_UP      => 2;

our @EXPORT_OK = qw(DB_DOWN DB_BOUNCED DB_UP);

1;
