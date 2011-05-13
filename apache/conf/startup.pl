BEGIN {
    if ($ENV{CBROOTLOCAL}) { unshift(@INC, "$ENV{CBROOTLOCAL}/lib") }
}
use lib "$ENV{CBROOT}/lib";
use lib "$ENV{CBROOTLOCAL}/cpan/lib/perl5";

use strict;
use Apache::DBI;
use Data::Dumper;
use Combust::Control::Basic;
use Combust::Control::Error;
use Combust::Notes;
use Combust::Redirect;
use Combust::Config;

use Combust::Constant qw(OK);

if ($ENV{CBROOTLOCAL}) {
    my $file = "$ENV{CBROOTLOCAL}/apache/conf/startup.pl";
    require $file if -e $file;
}


1;
