# Tell Perl where our lib is (ALWAYS use this)
use lib "$ENV{HOME}/perl5/lib/perl5";

# ensure we declare everything correctly (ALWAYS use this)
use strict;

# Give us diagnostic warnings where possible (ALWAYS use this)
use warnings;

# Allow us to build our application
use Plack::Builder;

# A basic app
my $default_app = sub {
    my $env = shift;
    my $cmd = "touch /tmp/" . $env->{PATH_INFO};
   # system($cmd);
    return [
        200,    # HTTP Status code
        [ 'Content-Type' => 'text/html' ],    # HTTP Headers,
        ["All is good"]                       # Content
    ];
};

# Run the builder for our application
return builder {
    $default_app;
}
