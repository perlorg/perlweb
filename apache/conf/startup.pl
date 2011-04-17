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

my $config = new Combust::Config;

my $trust_all = 0;
my $net_netmask_loaded;
my @forwarders;

for my $ip ($config->proxyip_forwarders) {

    $ip eq '*' and $trust_all = 1 and next;

    unless ($ip =~ m!/!) {
        push @forwarders, $ip;
        next;
    }

    unless ($net_netmask_loaded or ($net_netmask_loaded = eval { require Net::Netmask; 1; })) {
        warn "Net::Netmask not installed, could not use $ip as a proxyip_forwarder";
        next;
    }

    $ip = Net::Netmask->new2($ip);
    warn "Error defining trusted upstream proxy: " . Net::Netmask::errstr() unless $ip;
    push @forwarders, $ip if $ip;

}

sub ProxyIP::handler {
    my $r = shift;

    return OK unless $trust_all or trusted_ip($r->connection->remote_ip);

    my @ip = split(/,\s*/, ($r->headers_in->{'X-Forwarded-For'} || ''));
    while (my $ip = pop(@ip)) {
        $r->connection->remote_ip($ip);
        last unless trusted_ip($ip);
    }
    return OK;
}

sub trusted_ip {
    my $ip = shift;
    for my $fw (@forwarders) {
        return 1 if (ref $fw ? $fw->match($ip) : ($ip eq $fw));
    }
    return 0;
}

if ($ENV{CBROOTLOCAL}) {
    my $file = "$ENV{CBROOTLOCAL}/apache/conf/startup.pl";
    require $file if -e $file;
}


1;
