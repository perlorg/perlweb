#!/usr/bin/env perl

## This app.psgi is ONLY FOR DEVELOPMENT it makes it possible to edit the
## learn website without having to setup Combust
## specifically no database or ENV configuration is required

use strict;
use warnings;

use Path::Class;
use Template::Plugin::JSON 0.06;
use Template::Plugin::Comma;
use Template::Plugin::Shuffle;
use Plack::Middleware::TemplateToolkit;
use Plack::Middleware::Debug 0.12;
use Plack::Builder;
use Plack::Middleware::ErrorDocument;
use Plack::Middleware::Static;

my $root   = dir('./')->stringify();
my $shared = dir('../shared')->stringify();
my $static = dir('../')->stringify();

my $var_function = sub {
    # Just enough to make it site work
    return {
        combust => {
            static_url => sub {
                my $path = shift;
                return $path =~ /^\// ? "/static$path" : "/static/$path";
            },
            site => sub {
                return 'learn';
            },
        },
        page => { css => [], }

    };

};

# TT process
my $app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH => [ ( $root, $shared, $static ) ],
    PROCESS      => 'tpl/wrapper',
    PRE_PROCESS  => 'tpl/defaults',
    vars         => $var_function,
)->to_app;

## Static content (note: CSS is not static because of combust.static_url)

# docs/
$app = Plack::Middleware::Static->wrap(
    $app,
    path => qr{(gif|pl|png|jpg|swf|ico|mov|mp3|pdf|js)$},
    root => $static,
);

# docs/shared/
$app = Plack::Middleware::Static->wrap(
    $app,
    path         => qr{(gif|pl|png|jpg|swf|ico|mov|mp3|pdf|js)$},
    root         => $shared,
    pass_through => 1,
);

# docs/learn/
$app = Plack::Middleware::Static->wrap(
    $app,
    path         => qr{(gif|pl|png|jpg|swf|ico|mov|mp3|pdf|js)$},
    root         => $root,
    pass_through => 1,
);

return builder {

    # enable 'Debug', panels => [qw(DBITrace Memory Timer)];
    enable sub {

        # Combust supports .v1.gif for the CDN or something
        # strip that out for local developement
        my $lapp = shift;
        return sub {
            my $env = shift;
            if ( $env->{PATH_INFO} =~ /\.v\d+\./ ) {
                $env->{REQUEST_URI} =~ s{\.v\d+\.}{\.};
                $env->{PATH_INFO}   =~ s{\.v\d+\.}{\.};
            }
            $app->($env);
        };
    };

    $app;
}
