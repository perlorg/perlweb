BEGIN { if ($ENV{CBROOTLOCAL}) { use lib "$ENV{CBROOTLOCAL}/lib" } }
use lib "$ENV{CBROOT}/lib";

use Apache::DBI;

use Data::Dumper;
use Combust::Control::Basic;
use Combust::Control::Error;
use Combust::Notes;
use Combust::Redirect;

#use Combust::UserID;

BEGIN {
  if ($ENV{CBROOT} =~ m/redrock/) {
    require RRE::Control;
    require RRE::Control::RSS;
  }
}

sub ProxyIP::handler {
    my $r = shift;
    return OK unless $r->connection->remote_ip =~ m/^(127\.0\.0\.1)$/;

    my @ip = split(/,\s*/, $r->header_in('X-Forwarded-For'));
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
