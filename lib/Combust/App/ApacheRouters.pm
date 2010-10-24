package Combust::App::ApacheRouters;
use Moose::Role;
use Config::General ();
use Combust::Config ();

has 'apache_config_file' => (
  is => 'ro',
  isa => 'Str',
  default => sub { my $work_path = Combust::Config->new->work_path;
                   return $work_path . '/httpd.conf';
               }
);

has 'apache_config' => (
   is => 'rw',
   isa => 'HashRef',
   lazy_build => 1,
);

sub BUILD {}

before 'BUILD' => sub {
    my $self   = shift;

    warn "ApacheRouters Buikd";

    my $apache = $self->apache_config;
    if (%$apache) {

        my @virt;
        while (my ($port, $data) = each %{$apache->{VirtualHost}}) {
            push @virt, ref $data ? @{$data} : $data;
        }

        use Data::Dumper qw(Dumper);

        for my $virt (@virt) {
            
            #warn Dumper(\$virt);

            my @vars;
            if ($virt->{PerlSetVar}) {
                @vars = (
                ref $virt->{PerlSetVar}
                  ? @{$virt->{PerlSetVar}}
                  : $virt->{PerlSetVar});
            }

            my $domain = $virt->{ServerName};
            my ($site_name) = map { s/^site\s+//; $_ } grep {m/^site\s+/} @vars;
            $site_name ||= 'combust-default' if $domain eq 'combust-default';

            my $site = $self->sites->{$site_name}
              ||= Combust::Site->new(name => $site_name, domain => $domain);
            my $router = $site->router;

            $site->domain($domain) unless $site->domain;
            $site->domain_aliases(
                [   grep {$_} ref $virt->{ServerAlias}
                    ? @{$virt->{ServerAlias}}
                    : $virt->{ServerAlias}
                ]
            );

            $self->_connect_locations($router, $virt->{Location});

        }
    }

};

sub _build_apache_config {
    my $self = shift;
    
    my $config = Config::General->new(
        -ConfigFile       => $self->apache_config_file,
        -ApacheCompatible => 1
    );

    my %config = $config->getall;

    return \%config;
}

sub _connect_locations {
    my ($self, $router, $locations) = @_;

    my @locations = sort { length $b <=> length $a } keys %$locations;

    for my $location (@locations) {
        my $loc_data = $locations->{$location};
        next if $loc_data->{SetHandler} eq 'server-status';
        next if $loc_data->{SetHandler} eq 'cgi-script';

        if ($loc_data->{SetHandler} eq 'default-handler') {
            $loc_data->{SetHandler}  = 'perl-script';
            $loc_data->{PerlHandler} = 'Combust::Control::Static';
        }

        if ($loc_data->{SetHandler} eq 'perl-script') {

            my $handler = $loc_data->{PerlHandler} || $loc_data->{PerlResponseHandler};
            die "no PerlHandler for $location" unless $handler;
            $handler =~ s/->super//;

            $location .=
              $location =~ m{/$}
              ? ".*"
              : "(?:/.*)?";

            $router->connect(
                qr{($location)} => {
                    controller => $handler,
                    action     => 'render',
                }
            );

            next;
        }
        die "Unsupported handler $loc_data->{SetHandler}";
    }
}

1;
