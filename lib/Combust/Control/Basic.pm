package Combust::Control::Basic;
use strict;
use base 'Combust::Control';
use Combust::Config;
use Combust::Template::Provider;
use LWP::MediaTypes qw(guess_media_type);
use IO::File;
use Combust::Constant qw(OK DONE);

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(force_template_processing));

my $config = Combust::Config->new();

LWP::MediaTypes::read_media_types( $config->root . "/apache/conf/mime.types");

sub render {
  my $self = shift;

  my $template = '';

  my $uri = $self->request->path;

  warn "URI: $uri";

  # Don't serve special files:
  #    Normally, we want to use DirectoryMatch for this, but URI->File
  #    mapping is handled in this controller and parents.
  return 404
    if $uri =~ m!/(?:\.svn|tpl)/!;
  # we don't need /\.ht.* here, because they aren't special in
  # combust.

  # Some special handlers
  return $self->deadlink_handler()
    if $uri =~ m{^/!dl/.*};

  # Equivalent of Apache's DirectoryIndex directive
  $uri =~ s!/$!/index.html!;

  if (!$self->force_template_processing and $uri !~ m!/(.*\.(?:html?))$!) {
      warn "going to serve a static file";
      return $self->serve_static_file;
  }

  my $content_type;

  if ($uri =~ m!^/((?:[^/]+/)*[^/]+)$!) {
    $template = $1; 
    $template =~ s/\.\.+//g;
    $content_type = guess_media_type($template) || 'text/html';
  }
  else {
    return 404;
  }    

  my $output = eval { $self->evaluate_template($template); };
  if (my $err = $@ or !defined $output) {
    warn "TT ERROR: ",  $self->tt->error;
    warn "ERROR: $err";
    $self->request->notes('error', $err);
    return 404 if $err =~ m/: not found/;
    return 500;
  }

  return OK, $output, $content_type;
}

sub serve_static_file {
    my $self = shift;

    my $uri = $self->request->uri; 

    if ($uri =~ s!^(/.*)\.v[0-9a-f.]+\.(js|css|gif|png|jpg|ico)$!$1.$2!) {
        my $max_age = 315360000; # ten years
        $self->request->header_out('Expires', HTTP::Date::time2str( time() + $max_age ));
        $self->request->header_out('Cache-Control', "max-age=${max_age},public");
        $self->request->uri($uri);
    }


    # if the filename does not end in .html, then do not process it
    # with TT and just send it.
    my $file = $uri;
    substr($file,0,1) = ""; # trim leading slash

    my $content_type;

    my $data = $self->tt->provider->expand_filename($file);
    #warn Data::Dumper->Dump([\$data],[qw(data)]);
    if ($data->{path}) {
        $content_type = guess_media_type($data->{path});
        my $fh = IO::File->new($data->{path}, "r")
          or warn "Could not open $data->{path}: $!" and return 403;
        return OK, $fh, $content_type;
    }
    else {
        if ($self->tt->provider->is_directory($file)) {
            return $self->redirect($uri . "/", 1);
        }
        else {
            return 404;
        }
    }
}

sub deadlink_handler {
  my $self = shift;
  my $r = $self->request;

  # it's possible this should be an entirely seperate handler, but
  # that seems like overkill.
  $r->path =~ m{^/!dl/(.*)$};
  my $url = $1;

  # some simple validation
  return 500
    unless $url =~ m{^https?://?};

  my $template = "error/deadlink.html";

  $self->tpl_param(url => $url);

  if ($r->header_in("User-Agent") =~ /nodeworks/i) {
    # link checkers get 200s
    $r->status(203);
  } else {
    # everyone else gets a 404
    $r->status(404);
  }

  my $output = $self->evaluate_template($template);
  return OK, $output, "text/html";
}

1;
