use lib "$ENV{CBROOT}/lib";

use Data::Dumper;
use Combust::Control::Basic;
use Combust::Control::Error;
use Combust::Notes;

#use Combust::UserID;

sub ProxyIP::handler {
    my $r = shift;
    return OK unless $r->connection->remote_ip =~ m/^(127\.0\.0\.1)$/;

    my @ip = split(/,\s*/, $r->header_in('X-Forwarded-For'));
    if (my $ip = pop(@ip)) {
	$r->connection->remote_ip($ip);
    }
    return OK;
}


1;
