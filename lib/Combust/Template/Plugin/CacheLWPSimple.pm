
package Combust::Template::Plugin::CacheLWPSimple;

use strict;

use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;

use Cache::FileCache;

use LWP::UserAgent;

$VERSION = '0.01';

# This could also inherit from Template::Plugin::Cache, and duplicate
# less things.  It has many things copied from there.  See its
# documentation for more information.

# It doesn't actually use LWP::Simple, in order to provide a little
# more flexibility.

#------------------------------------------------------------------------
# new(\%options)
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $params) = @_;

    my $ua = LWP::UserAgent->new(
				 keep_alive => 1,
				 timeout => 30,
				 agent => "Combust-LWPSimple/$VERSION",
				);

    my $cache = Cache::FileCache->new( { $params ? %$params : (),
					 cache_root => "$ENV{CBROOT}/var/cache"
				       }
					);

    my $self = bless {
                      CACHE   => $cache,
                      CONFIG  => $params,
                      CONTEXT => $context,
		      UA      => $ua,
                     }, $class;

    return $self;
}


#------------------------------------------------------------------------
# $cache->include({
#                 template => 'foo.html',
#                 keys     => {'user.name', user.name},
#                 ttl      => 60, #seconds
#                });
#------------------------------------------------------------------------

sub get {
    my ($self, $params) = @_;
    my $cache_keys = $params->{keys};

    die "Required paramater 'url' not provided"
      unless exists $params->{url};

    my $key = join(
                   ':',
                   (
                    $params->{url},
                    map { "$_=$cache_keys->{$_}" } keys %{$cache_keys}
                   )
                  );
    my $result = $self->{CACHE}->get($key);
    if (!$result) {
      $result = $self->{UA}->get( $params->{url} );
      $result = $result->content if $result;
      print STDERR "got result" . scalar localtime() . "\n";
      # $result = $self->{CONTEXT}->$action($params->{template});
      $self->{CACHE}->set($key, $result, $params->{ttl});
    }
    return $result;
}
