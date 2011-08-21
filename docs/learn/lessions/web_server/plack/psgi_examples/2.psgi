use lib "$ENV{HOME}/perl5/lib/perl5";

use strict;
use warnings;
use Plack::Builder;

# 'mount' applications on specific URLs
use Plack::App::URLMap;

# Get directory listings and serve files
use Plack::App::Directory;

my $default_app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/html' ], ["All is good"] ];
};

# Get the Directory app, configured with a root directory
my $dir_app = Plack::App::Directory->new( { root => "/tmp/" } )->to_app;

# Create a mapper object
my $mapper = Plack::App::URLMap->new();

# mount our apps on urls
$mapper->mount('/'    => $default_app);
$mapper->mount('/tmp' => $dir_app);

# extract the new overall app from the mapper
my $app = $mapper->to_app();

# Run the builder for our application
return builder {
    $app;
}
