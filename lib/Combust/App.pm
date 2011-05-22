package Combust::App;
use Moose;
use Plack;
use Plack::Builder;
use Plack::Request;
use Combust::Config;
use Combust::Site;
use Combust::Request::Plack;

my $config = Combust::Config->new;

use namespace::clean -except => 'meta';

has sites => (
  is  => 'rw',
  isa => 'HashRef[Combust::Site]', 
  default => sub { {} },
);

has domain_mapping => (
  is  => 'rw',
  isa => 'HashRef',
  default => sub { {} },
);

has errorlog_stderr => (
  is      => 'ro',
  isa     => 'Bool',
  default => sub { 1 },
);

sub setup_mappings {
    my $self = shift;

    my %domains;
    for my $site (values %{ $self->sites }) {
        for my $domain ( $site->domain, $site->domain_alias_list ) {
            if ($domains{$domain} && $domains{$domain} ne $site->name) {
                die "$domain specified twice (for $domains{$domain} and ", $site->name;
            }
            $domains{$domain} = $site->name;
        }
    }

    #warn "DOMAINS : ", Data::Dumper::Dumper(\%domains);

    $self->domain_mapping(\%domains);
}

sub map_domain_site {
    my ($self, $request) = @_;
    my $domain    = $request->base->host;
    my $site_name = $self->domain_mapping->{$domain} || $self->domain_mapping->{'*'};
    my $site      = $site_name && $self->sites->{$site_name};
    return $site ? $site : $self->sites->{'combust-default'};
}

sub setup_request {
    my ($self, $env) = @_;

    my $request = Combust::Request::Plack->new($env);
    my $site = $self->map_domain_site($request);
    $request->site($site);

    return $request;
}

has 'rewriter' => (
    is => 'rw',
    required => 0,
);

sub exec {

    my ($self, $env) = @_;
    my $request = $self->setup_request($env);

    #warn "ENV: ", pp(\$env);

    {
        my $r = $self->rewriter->rewrite($request) if $self->rewriter;
        return $r if $r;
    }

    my $match = $request->site->router->match($request->env);

    {
        my $module = $match->{controller};
        $module =~ s{::}{/}g;
        require "$module.pm";
    }

    my $controller = $match->{controller}->new(request => $request);

    my $r = $controller->run($match->{action} || 'render');

    use Data::Dump qw(pp);
    # warn "RETURN: ", pp($r);

    return $r;
}

sub init {
    my $self = shift;
    $self->setup_mappings;
}

sub reference {
    my $self = shift;
    $self->init;
    my $app = sub { $self->exec(@_) };

    my $log_path = $config->log_path;

    my $logfh;

    if ($config->use_cronolog) {

        my $path     = $config->cronolog_path;
        my $log_file = $log_path . "/" . $config->cronolog_template;
        my $err_file = $log_file;
        $log_file =~ s/LOGFILE/access/;
        $err_file =~ s/LOGFILE/error/;

        my $log_params = $config->cronolog_params;
        $log_params =~ s/LOGDIR/$log_path/;
        my $err_params = $log_params;
        $log_params =~ s/LOGFILE/access/;
        $err_params =~ s/LOGFILE/error/;

        open $logfh, "|-", "$path $log_params $log_file"
          or die "Could not run $path: $!";

        unless ($self->errorlog_stderr) {
            open STDERR, "|-", "$path $err_params $err_file"
              or die "Could not run $path: $!";
        }

    }
    else {
        my $log_file = $log_path . "/access_log";
        my $err_file = $log_path . "/error_log";

        open $logfh, ">>", $log_file
          or die "Could not open $log_file: $!";

        unless ($self->errorlog_stderr) {
            open STDERR, ">>", $err_file or die $!;
        }
    }

    $logfh->autoflush(1);
    STDERR->autoflush(1);

    my $trust_all = _get_forwarders();

    builder {
        enable "Options";
        enable_if {
            my $remote_ip = $_[0]->{REMOTE_ADDR};
            $trust_all or _trusted_ip($remote_ip)
        } "Plack::Middleware::ReverseProxy";
        enable "AccessLog", logger => sub { print $logfh @_ };
        return $app;
    }
}

my $_forwarders = [];

sub _trusted_ip {
    my $ip = shift;
    for my $fw (@$_forwarders) {
        return 1 if (ref $fw ? $fw->match($ip) : ($ip eq $fw));
    }
    return 0;
}


sub _get_forwarders {

    my $trust_all = 0;
    my $net_netmask_loaded;
    my @forwarders;

    for my $ip ($config->proxyip_forwarders) {

        if ($ip eq '*') {
            return (1, []);
        }

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

    $_forwarders = \@forwarders;

    return 0;
}

1;
