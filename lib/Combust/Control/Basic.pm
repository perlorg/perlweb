package Combust::Control::Basic;
use strict;
use base 'Combust::Control';
use Combust::Template::Provider;
use LWP::MediaTypes qw(guess_media_type);;

# FIXME|TODO  
#   - sub class Template::Service to do the branch magic etc?
#   - use/take code from Apache::Template? (probably not)

# FIXME|TODO use setup_provider or some such to set this up. 
#my $provider = Combust::Template::Provider->new(
#   INCLUDE_PATH => [
#		    "$ENV{CBROOT}/docs/www/live",
#		    'http://svn.develooper.com/perl.org/docs/www/live',
#		   ],
#);

LWP::MediaTypes::read_media_types("/home/perl/apache1/conf/mime.types");

sub handler($$) {
  my ($class, $r) = @_;

  my $template = '';
  my $content_type = 'text/html';
  my $uri = $r->uri;

  # TODO|FIXME: get branch etc from a cookie and/or query args.

  $uri =~ s!/$!/index.html!;

  # TODO|FIXME: set last_modified_date properly!  

  if ($uri !~ m!/(.*\.(?:html?))$!) {
    # not a html (TT) file
    my $file = $uri;
    substr($file,0,1) = ""; # trim leading slash
    #warn "going to load $file";
    my ($data, $error) = $class->provider->load($file);
    if ($data and !$error) {
      $content_type = guess_media_type($file);
      return $class->send_output($r, $data, $content_type);
    }
    else {
      return 404;
    }
  }

  if ($uri =~ m!^/([^/]+)$!) {
    # FIXME|TODO: clean up url? 
    $template = $1; 
  }
  else {
    return 404;
  }    

  my $output;
  my $rv = $class->evaluate_template($r, output => \$output, template => $template, params => {});
  if ($@) {
    $r->pnotes('error', $@);
    return 404 if $@ =~ m/not found$/;
    return 500; 
  }
  $class->send_output($r, \$output, $content_type);
}



1;
