package Combust::Gearman;
use strict;
use Combust::Config;

my $config      = Combust::Config->new;
my $job_servers = [ $config->job_servers ];
my $http_port   = $config->port;

sub _c_job_servers {
    $job_servers
}

sub _prefix {
    return $http_port . "_";
}

1;
