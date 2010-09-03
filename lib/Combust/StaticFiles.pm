package Combust::StaticFiles;
use strict;
use List::Util qw(first max);
use JSON::XS ();
use Carp qw(cluck croak);
use Combust::Config;

use namespace::clean;

my $config = Combust::Config->new;
my $startup_time = time;
my $static_file_paths = {}; 
my $json = JSON::XS->new->relaxed(1);

sub new {
    my $proto = shift;
    my %args = (
        # defaults go here ...
        @_,
    );

    croak "site or setup parameter required"
      unless $args{site} or $args{setup};

    my $self = bless \%args, $proto;

    unless ($self->{setup}) {
        my @sites = $config->sites_list;
        for my $site (@sites) {
            $self->setup_static_files($site);
        }
    }

    return $self;
}

sub deployment_mode {
    my $self = shift;
    return $config->site->{$self->site}->{deployment_mode} || 'test';
}

sub find_static_path {
    my ($self, $site) = @_;
    my $root_dir = $config->root_docs;

    my @static_dirs = ($root_dir . "/$site/static",
                       $root_dir . "/static",
                       $root_dir . "/shared/static",
                      );
    return first { -e $_ && -d _ } @static_dirs;
}

sub setup_static_files {
    my ($self, $site) = @_;

    my $static_directory = $self->find_static_path($site);
    return unless $static_directory;

    $static_file_paths->{$site}->{path} = $static_directory;

    my $static_files = 
        eval { retrieve("${static_directory}/.static.versions.store") }
        || $self->_load_json("${static_directory}/.static.versions.json");

    # TODO: in devel deployment mode we should reload this
    # automatically when the .json file changes
    my $static_groups_file = "${static_directory}/.static.groups.json";
    my $static_groups = -r $static_groups_file && $self->_load_json($static_groups_file) || {};

    # no relative filenames in the groups
    for my $name (keys %$static_groups) {
        my $group = $static_groups->{$name};
        $group->{files} = [ map { $_ =~ m!^/! ? $_ : "/$_"  } @{ $group->{files} } ];
    }

    $static_file_paths->{$site}->{groups} = $static_groups;
    $static_file_paths->{$site}->{files}  = $static_files;
}

sub _load_json {
    my ($self, $file) = @_;
    return {} unless -r $file;
    my $data = 
        eval { 
            local $/ = undef;
            open my $fh, $file or die "Could not open $file: $!";
            my $versions = <$fh>;
            return $json->decode($versions)
    };
    warn $@ if $@;
    return $data;
}

sub _save_json {
    my ($self, $file, $data) = @_;
    my $json = $json->encode($data);
    open my $fh, '>', $file or die "could not open $file: $!";
    print $fh $json;
    close $fh or die "Could not close $file: $!";
}

sub static_file_paths {
    my $self = shift;
    return $static_file_paths->{$self->site};
}

sub static_base {
    my ($self, $site) = @_;
    $site = $site || $self->site;
    my $base = $config->site->{$site} && $config->site->{$site}->{static_base};
    $base ||= '/static';
    $base =~ s!/$!!;
    $base;
}

sub static_base_ssl {
    my ($self, $site) = @_;
    $site = $site || $self->site;
    my $base = $config->site->{$site} && $config->site->{$site}->{static_base_ssl};
    return $self->static_base($site) unless $base;
    $base =~ s!/$!!;
    $base;
}


sub static_group {
    my ($self, $name) = @_;
    my $data = $self->static_group_data($name);
    return unless $data;
    return "/.g/$name" if $self->deployment_mode ne 'devel'; 
    return @{ $data->{files} };
}

sub static_group_data {
    my ($self, $name) = @_;
    my $groups = $static_file_paths->{$self->site} && $static_file_paths->{$self->site}->{groups};
    return $groups && $groups->{$name};
}

sub static_groups {
    my $self = shift;
    my $groups = $static_file_paths->{$self->site} && $static_file_paths->{$self->site}->{groups};
    return () unless $groups;
    return sort keys %$groups;
}

sub site { return shift->{site} } 

sub static_url {
    my ($self, $file) = @_;
    $file or cluck "no filename specified to static_url" and return "";
    $file = "/$file" unless $file =~ m!^/!;

    my $regexp = qr/(\.(js|css|gif|png|jpg|ico))$/;

    my $file_attr;

    if ($file =~ m/$regexp/ and my $static_files = $static_file_paths->{$self->site}) {
        my $version;
        if ($self->deployment_mode eq 'devel') {
            my $static_directory = $static_files->{path};
            $version = max($startup_time, (stat("${static_directory}$file"))[9]);
        }
        elsif (ref $static_files->{files}->{$file}) {
            ($version, $file_attr) = (@{$static_files->{files}->{$file}});
        }

        if ($file_attr and $file_attr->{min}) {
            $file =~ s!$regexp!-min$1!;
        }

        $file =~ s!$regexp!.v$version$1! if $version;
    }

    return $self->static_base($self->site) . $file;
}



1;
