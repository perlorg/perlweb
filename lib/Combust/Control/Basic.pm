package Combust::Control::Basic;
use strict;
use base 'Combust::Control';
use Combust::Template::Provider;

# FIXME|TODO  
#   - sub class Template::Service to do the branch magic etc?
#   - use/take code from Apache::Template? (probably not)

# FIXME|TODO use setup_provider or some such to set this up. 
my $provider = Combust::Template::Provider->new(
   INCLUDE_PATH => [
		    "$ENV{CBROOT}/docs/www/live",
		    'http://svn.develooper.com/perl.org/docs/www/live',
		   ],
);

sub handler($$) {
  my ($class, $r) = @_;

  my $template = '';
  my $content_type = 'text/html';
  my $uri = $r->uri;

  # TODO|FIXME: get branch etc from a cookie and/or query args.

  $uri =~ s!/$!/index.html!;

  # TODO|FIXME: set last_modified_date properly!  
 
  if ($uri =~ m!/(.*\.(gif|jpe?g|png|css))$!) {
    my $file = $1;
    #warn "going to load $file";
    my ($data, $error) = $provider->load($file);
    if ($data and !$error) {
      # Set the right content type (!)
      return $class->send_output($r, \$data->{text}, 'image/gif');
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
