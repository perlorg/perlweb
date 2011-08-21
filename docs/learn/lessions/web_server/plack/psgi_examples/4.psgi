use lib "$ENV{HOME}/perl5/lib/perl5";

use strict;
use warnings;
use Plack::Builder;
use Plack::App::URLMap;
use Plack::App::Directory;

my $root = '/path/to/htdocs/';

my $default_app = Plack::App::TemplateToolkit->new(
    root => $root,    # Required
)->to_app();

my $dir_app = Plack::App::Directory->new( { root => "/tmp/" } )->to_app;

my $mapper = Plack::App::URLMap->new();

$mapper->mount( '/'    => $default_app );
$mapper->mount( '/tmp' => $dir_app );

# extract the new overall app from the mapper
my $app = $mapper->to_app();

# Run the builder for our application
return builder {

    # Page to show when requested file is missing
    enable "Plack::Middleware::ErrorDocument",
        404 => "$root/page_not_found.html";

    # These files can be served directly
    enable "Plack::Middleware::Static",
        path => qr{[gif|png|jpg|swf|ico|mov|mp3|pdf|js|css]$},
        root => $root;

    # Our application
    $app;
}
