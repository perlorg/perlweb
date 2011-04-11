package Combust::App;
use Moose;
use Plack;
use Plack::Builder;
use Plack::Request;
use Combust::Site;
use Combust::Request::Plack;

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
    my $domain = $request->base->host;
    my $site_name = $self->domain_mapping->{$domain};
    my $site = $site_name && $self->sites->{$site_name};
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

sub app {

    my ($self, $env) = @_;
    my $request = $self->setup_request($env);

    warn "ENV: ", pp(\$env);

    $self->rewriter->rewrite($request) if $self->rewriter;

    my $match = $request->site->router->match($request->env);

    {
        my $module = $match->{controller};
        $module =~ s{::}{/}g;
        require "$module.pm";
    }

    my $controller = $match->{controller}->new(request => $request);

    warn "calling controller!";

    my $r = $controller->run($match->{action} || 'render');

    use Data::Dump qw(pp);
    warn "RETURN: ", pp($r);

    return $r;
}

sub init {
    my $self = shift;
    $self->setup_mappings;
}

sub reference {
    my $self = shift;
    $self->init;
    sub { $self->app(@_); }
}

1;
