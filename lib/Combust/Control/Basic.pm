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

sub handler ($$) {
  my ($self, $r) = @_;
  
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
    # use sendfile to ship the data instead of loading everything first ...

    my $data = $self->provider->expand_filename($file);
    #warn Data::Dumper->Dump([\$data],[qw(data)]);
    if ($data->{path}) {
      $r->update_mtime($data->{time} || time);
      $content_type = guess_media_type($file);
      my $fh;
      open $fh, $data->{path} or warn "Could not open $data->{path}: $!" and return 403;
      return $self->send_output($r, \$fh, $content_type);
    }
    else {
      if ($self->provider->is_directory($file)) {
	return $self->redirect($r, $uri . "/", 1);
      }
      else {
	return 404;
      }
    }
  }

  # FIXME|TODO: disallow nasty characters here, in particular double dots...
  if ($uri =~ m!^/((?:[^/]+/)*[^/]+)$!) {
    $template = $1; 
  }
  else {
    return 404;
  }    

  my $output;
  my $rv = $self->evaluate_template($r, output => \$output, template => $template, params => $self->params);
  if ($@) {
    $r->pnotes('error', $@);
    return 404 if $@ =~ m/not found$/;
    return 500; 
  }
  $self->send_output($r, \$output, $content_type);
}



1;
