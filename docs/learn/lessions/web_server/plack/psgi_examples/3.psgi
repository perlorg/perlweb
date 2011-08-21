use lib "$ENV{HOME}/perl5/lib/perl5";

use strict;
use warnings;
use Plack::Builder;

use Plack::App::URLMap;
use Plack::App::Directory;

my $default_app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/html' ], ["All is good"] ];
};

my $dir_app = Plack::App::Directory->new( { root => "/tmp/" } )->to_app;

# mount our apps on urls
my $mapper = Plack::App::URLMap->new();
$mapper->mount('/'    => $default_app);
$mapper->mount('/tmp' => $dir_app);

# extract the new overall app from the mapper
my $app = $mapper->to_app();

# Run the builder for our application, and add extra Middleware
return builder {

    # These files can be served directly
    enable "Plack::Middleware::Static",
        path => qr{[gif|png|jpg|swf|ico|mov|mp3|pdf|js|css]$},
        root => $root;

    # Our application
    $app;
}
