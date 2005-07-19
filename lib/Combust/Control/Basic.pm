package Combust::Control::Basic;
use strict;
use base 'Combust::Control';
use Combust::Template::Provider;
use LWP::MediaTypes qw(guess_media_type);;
use Apache::Constants qw(OK);

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

LWP::MediaTypes::read_media_types("$ENV{APACHEROOT}/conf/mime.types");

sub render {
  my $self = shift;

  my $r = $self->r;
  
  my $template = '';
  my $content_type = 'text/html';
  my $uri = $r->uri;

  # Don't serve special files:
  #    Normally, we want to use DirectoryMatch for this, but URI->File
  #    mapping is handled in this controller and parents.
  return 404
    if $uri =~ m!/(?:\.svn|/tpl/)/!;
  # we don't need /\.ht.* here, because they aren't special in
  # combust.

  # Some special handlers
  return $self->deadlink_handler($r)
    if $uri =~ m{^/!dl/.*};

  # Equivalent of Apache's DirectoryIndex directive
  $uri =~ s!/$!/index.html!;

  # TODO|FIXME: set last_modified_date properly!  

  if ($uri !~ m!/(.*\.(?:html?))$!) {
    # if the filename does not end in .html, then do not process it
    # with TT and just send it.
    my $file = $uri;
    substr($file,0,1) = ""; # trim leading slash

    my $data = $self->provider->expand_filename($file);
    #warn Data::Dumper->Dump([\$data],[qw(data)]);
    if ($data->{path}) {
      $r->update_mtime($data->{time} || time);
      $content_type = guess_media_type($data->{path});
      $content_type = 'text/css' if $file =~ m/\.css$/;
      my $fh;
      open $fh, $data->{path} or warn "Could not open $data->{path}: $!" and return 403;
      return OK, $fh, $content_type;
    }
    else {
      if ($self->provider->is_directory($file)) {
	  warn "URI is $uri\n";
	return $self->redirect($uri . "/", 1);
      }
      else {
	return 404;
      }
    }
  }

  # FIXME|TODO: disallow nasty characters here, in particular double dots...
  if ($uri =~ m!^/((?:[^/]+/)*[^/]+)$!) {
    $template = $1; 
    $template =~ s/\.\.+//g;
    #warn "TEMPLATE: $template";
  }
  else {
    return 404;
  }    

  my $output = $self->evaluate_template($template);
  if ($@) {
    $r->pnotes('error', $@);
    return 404 if $@ =~ m/: not found/;
    return 500; 
  }
  return OK, $output, $content_type;
}

sub deadlink_handler {
  my ($self, $r) = @_;

  # it's possible this should be an entirely seperate handler, but
  # that seems like overkill.
  $r->uri =~ m{^/!dl/(.*)$};
  my $url = $1;

  # some simple validation
  return 500
    unless $url =~ m{^https?://?};

  my $template = "error/deadlink.html";

  $self->param(url => $url);

  if ($r->header_in("User-Agent") =~ /nodeworks/i) {
    # link checkers get 200s
    $r->status(203);
  } else {
    # everyone else gets a 404
    $r->status(404);
  }

  my $output = $self->evaluate_template($template);
  $r->update_mtime(time);
  $self->send_output($output, "text/html");

}

1;
