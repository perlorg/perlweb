package Combust::Control;
use Moose;
extends 'Combust::Base';

use Combust::Constant qw(OK SERVER_ERROR MOVED DONE DECLINED REDIRECT);
use Carp qw(confess cluck carp);
use Digest::SHA qw(sha1_hex);
use HTML::Entities ();
use Encode qw(encode_utf8);
use Scalar::Util qw(looks_like_number reftype);
use IO::Compress::Gzip qw(gzip $GzipError);

# TODO: figure out why we use this; remove it if possible
require bytes;

use Combust::Cache;
use Combust::Template;
use Combust::Cookies;
use Combust::Secret qw(get_secret);
use Combust::Config;

use namespace::clean -except => 'meta';

my $config = Combust::Config->new();

sub config { $config }

sub site { shift->request->site }

sub req_param {
  my $self = shift;
  $self->request->req_param(@_);
}

sub param  { cluck "param() deprecated; use tpl_param()"; tpl_param(@_) }
sub params { cluck "params() deprecated; use tpl_params()"; tpl_params(@_) }

sub tpl_param {
  my ($self, $key) = (shift, shift);
  return unless $key;
  #Carp::cluck "param('$key' ...) called" if $key eq "user";
  $self->{params}->{$key} = shift if @_;
  return $self->{params}->{$key};
}

sub tpl_params {
  my $self = shift;
  cluck("tpl_params called with [$self] as self.  Did you configure the handler to call ->handler instead of ->super?")
    unless ref $self;
  cluck('Combust::Control->tpl_params called with parameters, did you mean to call "param"?') if @_;
  $self->{params} || {};
}

sub init {
    return OK;
}

sub run {
    my $self   = shift;
    my $method = shift;

    $self->tt->set_include_path($self->get_include_path);
    my $init_status = OK;

    eval {
        $init_status = $self->init if $self->can('init');
    };
    if ($@) {
        cluck "$self->init died: $@";
        return SERVER_ERROR;
    }
    return $init_status unless $init_status == OK;

    my ($status, $output, $content_type) = eval { $self->do_request($method) };
    if (my $err = $@) {
        cluck "Combust::Control: oops, class handler died with: $err";
        return SERVER_ERROR;
    }

    # warn "STATUS RETURNED: $status";
    # warn "output returned: [$output]";

    unless ($status and $output) {

        $self->request->response->status or
          $self->request->response->status($status || 500);

        unless ($output) {

            my $error_header = "";
            $error_header = 'File not found' if $status == 404;
            $error_header = 'Server Error'   if $status == 500;

            my $error_text = $self->request->notes('error') || '';

            $self->tpl_param('error'        => $status);
            $self->tpl_param('error_header' => $error_header);
            $self->tpl_param('error_text'   => $error_text);
            $self->tpl_param('error_uri'    => $self->request->uri);

            $output = $self->evaluate_template("error/error.html")
              || "Error $status";
        }
    }

    if ($self->can('cleanup')) {
        eval { $self->cleanup };
        warn "CLEANUP method failed: $@" if $@;
    }

    return $self->send_output($output, $content_type);
}


sub do_request {
  my $self   = shift;
  my $method = shift || 'render';

  my $cache_info = $self->cache_info || {};

  my ($status, $output, $cache);

  if ($cache_info->{id} 
      && ($cache = Combust::Cache->new( type => ($cache_info->{type} || '') ))
     ) {
    my $cache_data;
    $cache_data = $cache->fetch(id => $cache_info->{id})
      unless $self->req_param('cache_bypass');

    if ($cache_data and $cache_data->{data}) {
      $self->post_process($cache_data->{data});
      $self->r->update_mtime($cache_data->{created_timestamp});
      my ($content_type);
      $content_type = $cache->{meta_data}->{content_type}
	if $cache->{meta_data}->{content_type};
      $status = $cache->{meta_data}->{status}
	if $cache->{meta_data}->{status};

      $status ||= OK;

      return ($status, $cache_data->{data}, $content_type);
    }
  }

  ($status, $output, my $content_type) = eval { $self->$method };
  if (my $err = $@) {
      if ($err =~ m{^(-?\d+)($|\sat\s\/)}) {
          $status = $1;
      }
      else {
          warn "render failed: $err";
          $status = SERVER_ERROR;
      }
  }
  if ($status == DONE) {
    return $self->{_response_ref}
      ? delete $self->{_response_ref}
      : [ $self->request->response->status ]
  }
  return ($status, $output, $content_type) unless $status == OK;

  # sometimes we end up here with "OK" but with no content ... gah.
  if ($cache and $output and $status != SERVER_ERROR and !$self->no_cache) {
    $cache_info->{meta_data}->{content_type} = $content_type if $content_type;
    $cache_info->{meta_data}->{status}       = $status || $self->r->status;
    $cache->store( %$cache_info, data => $output );
  }
  
  $status = $self->post_process($output);

  return ($status, $output, $content_type);
}

sub no_cache {
    my $self   = shift;
    my $status = shift;
    $self->{no_cache} = $status if defined $status;
    return $self->{no_cache};
}

sub cache_info {}
sub post_process { return OK }

sub _cleanup_params {
  my $self = shift;
  for my $param (keys %{$self->{params}}) {
    delete $self->{params}->{$param};
  }
}

sub r {
    cluck "r called";
    return shift->request;
}


sub evaluate_template {
  my $self      = shift;
  my $template  = shift;

  my $tpl_params    = { %{$self->tpl_params }, ($_[0] and ref $_[0] eq 'HASH') ? %{$_[0]} : @_ };

  local $tpl_params->{root} = $config->root;  # localroot anyone?
  local $tpl_params->{siteconfig} = $self->site && $self->config->site->{$self->site};

  local $tpl_params->{combust} = $self;

  local $tpl_params->{site} = $tpl_params->{site} || $self->site;

  my $output = eval { $self->tt->process($template, $tpl_params, { site => $tpl_params->{site} } ) };

  unless(defined $output) {
      my $err = $self->tt->error || $@;
      warn( (ref $self ? ref $self : $self) . "  - ". $self->request->request_url
            . " - error processing template $template: $err");
      die $err;
  }

  return $output;
}

my $ctemplate;

sub tt {
    $ctemplate ||= Combust::Template->new()
      or die "Could not initialize Combust::Template object: $Template::ERROR";
}

sub provider {
    my $self = shift;
    cluck "combust->provider is deprecated; use combust->tt->provider";
    $self->tt->provider(@_);
}

sub content_type {
  shift->request->content_type(@_);
}

sub send_cached {
  my ($self, $cache, $content_type) = @_;

  $self->r->update_mtime($cache->{created_timestamp});

  $content_type = $cache->{meta_data}->{content_type}
      if $cache->{meta_data}->{content_type};

  return $self->send_output($cache->{data}, $content_type);
}

sub default_character_set {
  'utf-8'
}

sub send_output {
  my $self = shift;

  #cluck "in send output!";
  
  my $output = shift;
  my $content_type = shift || $self->content_type || 'text/html';

  unless (defined $output) {
    cluck "send_output called with undefined output";
    return [404];
  }

  # for some reason mod_perl will sometimes forget to dereference
  # a reference, so let's not try printing those anymore.
  $output = $$output if ref $output and reftype($output) ne 'GLOB';

  $self->cookies->bake_cookies;

  # not that we actually have the /w3c/p3p.xml document
  $self->request->header_out('P3P',qq[CP="NOI DEVo TAIo PSAo PSDo OUR IND UNI NAV", policyref="/w3c/p3p.xml"]);

  my $length;
  if (ref($output) and reftype($output) eq "GLOB") {
    $length = ( stat($output) )[7]
      unless tied(*$output);    # stat does not work on tied handles
  }
  else {
    if ($content_type =~ m!^text/!) {

       # eek - this is certainly not correct, but seems to have worked for us...
        $output = encode_utf8($output);

        if (($self->request->header_in('Accept-Encoding') || '') =~ m/\bgzip\b/) {
            my $compressed;
            gzip \$output => \$compressed
              or die "gzip failed: $GzipError\n";
            $output = $compressed;

            $self->request->header_out('Content-Encoding' => 'gzip');
            $self->request->header_out(
                'Vary' => join ", ",
                grep {$_} $self->request->header_out('Vary'), 'Accept-Encoding'
            );

        }
    }

      # length in bytes
      $length = do { use bytes; length($output) };
  }

  $self->request->header_out('Content-Length' => $length)
    if defined $length;

  $content_type .= "; charset=" . $self->default_character_set
    if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
  $self->content_type($content_type);
  #warn "content_type: $content_type";

  #if ((my $rc = $r->meets_conditions) != OK) {
  #  $r->status($rc);
  #  return $rc;
  #}

  # if all that is requested is HEAD
  # don't send the body
  # return OK if $r->header_only;

  $self->request->response->status(200) unless $self->request->response->status;

  $self->request->response->content(ref $output
      && reftype($output) eq "GLOB" ? $output : [$output]);

  my $response_ref = $self->request->response->finalize;
  $self->{_response_ref} = $response_ref;

  #use Data::Dump qw(pp);
  #warn "RESP REF: ", pp($response_ref);

  return $response_ref;
}

sub redirect {
  my $self = shift;
  my $url = shift;
  my $permanent = shift;

  $url = $url->abs if ref $url =~ m/^URI/;

  # this should really check for a complete URI or some such; we'll do
  # that when it breaks on a ftp:// or whatever redirect :-)
  unless ($url =~ m!^https?://!i) {
    $url = $config->base_url($self->site) . $url;
  }

  #use Carp qw(cluck);
  #warn "redirecting to [$url]";

  $self->request->header_out('Location' => $url);

  my $status = $permanent ? MOVED : REDIRECT;
  $self->request->response->status($status);

  my $url_escaped = HTML::Entities::encode_entities($url);

  my $data = <<EOH;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD><TITLE>Redirect...</TITLE></HEAD><BODY>The document has moved <A HREF="$url_escaped">here</A>.<P></BODY></HTML>
EOH

  # allow setting custom headers etc - this doesn't bail out if the
  # status is wrong, unlike on the regular requests. (Just because we
  # don't care for that feature anyway).
  $self->post_process( $data );

  return $self->send_output( $data, 'text/html' );
}

sub cookies {
    my $self = shift;
    return $self->{_cookies} if $self->{_cookies};

    my $domain =
      $self->site && $self->config->site->{$self->site}->{cookie_domain}
      || '';

      my $cookies = Combust::Cookies->new(
        $self->request,

        # Combust::Request defaults this to r->hostname if it is not set
        domain => $domain,
      );

    return $self->{_cookies} = $cookies;
}

sub cookie {
  my $self = shift;
  $self->cookies->cookie(@_);
}

sub auth_token {
    my $self = shift;
    return $self->{_auth_token} if $self->{_auth_token};
    my $cookie = $self->cookie('uiq');
    my ($time, $uid) = split /-/, $cookie || '';
    # reset the auth_token twice a day
    $self->cookie('uiq', time . '-' . sha1_hex(time . rand)) unless $time and $time > time - 43200;
    return $self->{_auth_token} = _calc_auth_token( $self->cookie('uiq') );
}

sub _calc_auth_token {
    my $cookie = shift;
    my ($time, $uid) = split /-/, $cookie;
    # let the old auth tokens be good for up to a day
    ($time, my $secret) = get_secret(type => 'auth_token', time => $time, expires_at => $time + 86400 );
    return '2-' . sha1_hex( $secret . $cookie);
}

sub check_auth_token {
    my $self = shift;
    my $token_param = $self->req_param('auth_token') or return 0;
    return $token_param eq $self->auth_token;
}


# default api_class tries to guess what you wanted
sub api_class {
    my $class = shift;
    my ($api_class) = $class =~ m/^([^:]+)/;
    return "${api_class}::API" unless $api_class eq 'Combust';
    die 'api_class not defined in your controller';
}

sub api {
    my ($self, $method, $params, $args) = @_;

    my $api_params = {
             params   => $params,
             ($args ? (%$args) : ()),
       };

    if ( !exists $api_params->{user} and $self->can('user') ) {
        $api_params->{user} = $self->user;
    }

    return $self->api_class->call
      ($method,
       $api_params,
      );
}

sub deployment_mode {
    my $self = shift;
    my $dm = $self->config->site->{$self->site}->{deployment_mode} || 'test';
    warn "INVALID deployment_mode CONFIG for ", $self->site, "! Use devel, test or prod\n" unless $dm =~ m/^(devel|test|prod)$/;
    $dm;
}

1;
