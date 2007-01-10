BEGIN { if ($ENV{CBROOTLOCAL}) { unshift(@INC, "$ENV{CBROOTLOCAL}/lib") } }
use lib "$ENV{CBROOT}/lib";

use strict;
use Apache::DBI;
use Data::Dumper;
use Combust::Control::Redirect;
use Combust::Control::Basic;
use Combust::Control::Error;
use Combust::Notes;
use Combust::Redirect;
use Combust::Config;

use Apache::Constants qw(OK);

my $config = new Combust::Config;

sub ProxyIP::handler {
    my $r = shift;

    return OK
     unless grep { $_ eq '*' or $_ eq $r->connection->remote_ip } $config->proxyip_forwarders;

    my @ip = split(/,\s*/, ($r->header_in('X-Forwarded-For')||''));
    if (my $ip = pop(@ip)) {
	$r->connection->remote_ip($ip);
    }
    return OK;
}

if ($ENV{CBROOTLOCAL}) {
  my $file = "$ENV{CBROOTLOCAL}/apache/conf/startup.pl";
  require $file if -e $file;
}


1;
