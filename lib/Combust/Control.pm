package Combust::Control;
use strict;
use Exception::Class ('ControllerException');
use Apache::Request;
use Apache::Cookie;
use Apache::Constants qw(:common :response);
use Apache::File;
use Carp qw(confess cluck carp);
use Encode qw(encode_utf8);

use Apache::Util qw();

use Template;
use Template::Parser;
use Template::Stash;
#use Template::Constants qw(:debug);

use Combust::Template::Provider;
use Combust::Template::Filters;

use Combust::Template::Translator::POD;

use Combust::Cache;


use Combust::Config;

my $config = Combust::Config->new();

sub config { $config }

#use HTTP::Date qw(time2str); 

$Template::Config::STASH = 'Template::Stash::XS';

$Template::Stash::SCALAR_OPS->{ rand } = sub {
  return int(rand(shift));
    };

my $parser = Template::Parser->new(); 

my $root = $ENV{CBROOT};

my %provider_config = (
		       PARSER => $parser,
		       COMPILE_EXT      => '.ttc',
		       COMPILE_DIR      => $config->root_local . "/tmp/ctpl",
		       #TOLERANT => 1,
		       #RELATIVE => 1,
		       CACHE_SIZE       => 128,  # cache 128 templates
		       EXTENSIONS       => [ { extension => "pod",
					       translator => Combust::Template::Translator::POD->new()
					     },
					   ],
					     
		      );

$Combust::Control::provider ||= Combust::Template::Provider->new
  (
   %provider_config,
   INCLUDE_PATH => [
		    sub {
		      &get_include_path()
		    },
		    #'http://svn.develooper.com/perl.org/docs/www/live',
		   ],
  );

$Combust::Control::tt = Template->new
  ({
    FILTERS => { 'navigation' => [ \&Combust::Template::Filters::navigation_filter_factory, 1 ] },
    RELATIVE       => 1,
    LOAD_TEMPLATES   => [$Combust::Control::provider],
    #'LOAD_TEMPLATES' => [ $file, $http ],
    #PREFIX_MAP => {
    #               file => 0,
    #               http => 1,
    #		    default => 1,
    #	            },
    'PRE_PROCESS'    => 'tpl/defaults',
    'PROCESS'        => 'tpl/wrapper' ,
    'PLUGIN_BASE'    => 'Combust::Template::Plugin',
    #'DEBUG'  => DEBUG_VARS|DEBUG_DIRS|DEBUG_STASH|DEBUG_PARSER|DEBUG_PROVIDER|DEBUG_SERVICE|DEBUG_CONTEXT,
  }) or die "Could not initialize Template object: $Template::ERROR";

sub provider {
  $Combust::Control::provider;
}

sub tt {
  $Combust::Control::tt
}

sub r {
  my $self = shift;
  return $self->{_r} if $self->{_r};
  # some day we'll deprecate this...
  $self->{_r} = Apache::Request->instance(Apache->request);
}

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

sub new {
  my ($class, $r) = @_;

  # return if we are already blessed
  return $class if ref $class;

  my $self = bless( { } , $class);
  
  $self->{params} = {
    config => $config,
  };

  $self;
}

sub super ($$) {
  my $class   = shift;
  my $r = shift;

  confess(__PACKAGE__ . '->super got called without $r') unless $r;
  return unless $r;

  # Combust::Redirect ends up being called a bunch of times and in
  # turn runs through super here with all the setup required just to
  # be able to run $self->redirect when it needs to do that.  Not so
  # great. (in particular because we don't keep it around as a
  # singleton).

  # Storing it is a hack for get_include_path ...
  my $self = $class->new($r);
  $self->r->pnotes('controller', $self);

  my $status;
  
  eval {
    $status = OK;
    $status = $self->init if $self->can('init');
  };
  if ($@) {
    cluck "$self->init died: $@";
    return 500;
  }
  return $status unless $status == OK;

  eval {
    $status = $self->handler($self->r);
  };
  cluck "Combust::Control: oops, class handler died with: $@" if $@;
  return 500 if $@;

  # should we do this to make it harder for people to shoot themselves in the foot?
  # $self->_cleanup_params;

  return $status;
}

sub handler {
  my $self = shift;
  unless ($self->can('render')) {
    my $msg = "$self doesn't have a render method; you probably got the inheritance order messed up somewhere.";
    warn $msg;
    die $msg;
  }
  my ($status, $output, $content_type) = $self->do_request();
  # have to return 'OK' and fake it with r->status or some such to make a custom 404 easily
  return $status unless $status == OK;
  return $self->send_output($output, $content_type);
}

sub do_request {
  my $self = shift;

  my $cache_info = $self->cache_info || {};

  my ($status, $output, $cache);

  if ($cache_info->{id} 
      && ($cache = Combust::Cache->new( type => ($cache_info->{type} || '') ))
     ) {
    my $cache_data = $cache->fetch(id => $cache_info->{id});
    if ($cache_data) {
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

  ($status, $output, my $content_type) = $self->render;
  return $status unless $status == OK;

  if ($cache) {
    $cache_info->{meta_data}->{content_type} = $content_type if $content_type;
    $cache_info->{meta_data}->{status}       = $status || $self->r->status;
    $cache->store( %$cache_info, data => $output );
  }
  
  $status = $self->post_process($output);

  return ($status, $output, $content_type);
}

sub cache_info {}
sub post_process { OK }

sub _cleanup_params {
  my $self = shift;
  for my $param (keys %{$self->{params}}) {
    delete $self->{params}->{$param};
  }
}

sub get_include_path {
  my $r = Apache->request;

  my $self = $r->pnotes('controller');

  $r = Apache::Request->instance($r);

  my $site = $r->dir_config("site");
  unless ($site) {
    my $path = [ $r->document_root ] if $r->dir_config('UseDocumentRoot');
    push @$path, "$root/apache/root_templates/";
    return $path;
  }

  my $site_dir = $config->site->{$site}->{docs_site} || $site;

  #warn Data::Dumper->Dump([\$r], [qw(r)]);

  my $cookies = $self->cookies;

  #warn "param:root: ", $r->param('root');
  #warn "root coookie : ", $cookies->cookie('root');

  my ($user, $dir);
  my $root_param = $r->param('root') || '';
  if (($user, $dir) = ($root_param =~ m!^/?([a-zA-Z]+)/([^\.]+)$!)) {
    # FIXME|TODO: should expand on ~ instead of using /home
    $cookies->cookie('root', "$user/$dir");
  } 
  elsif ($root_param eq "/") {
    # don't set user and dir, reset the cookie
    $cookies->cookie('root', "/");
  }
  elsif (($user, $dir) = (($cookies->cookie('root')||'') =~ m!^([a-zA-Z]+)/([^\.]+)$!)) {
    # ...  why is this in an elsif?  :-)
  }

  $r->pnotes('combust_notes')->{include_root} = ($user and $dir) ? "/$user/$dir" : '/';

  my $path;

  my $docs = $config->docs_name;

  if ($user and $dir) {
    $user = "/home/$user";
    $path = [
	     "$user/$docs/$dir/$site_dir/",
	     "$user/$docs/$dir/shared/",
	     "$user/$docs/$dir/",
	    ];
  }
  else {
    my $root_docs = $config->root_docs,
    # TODO: root=/something should set dir to 'something'
    $dir = 'live';
    $path = [
	     "$root_docs/$dir/$site_dir/",
	     "$root_docs/$dir/shared/",
	     "$root_docs/$dir/",
	    ];
  }


  $path = [ $r->document_root ] if $r->dir_config('UseDocumentRoot');
  push @$path, "$root/apache/root_templates/";

  #warn Data::Dumper->Dump([\$path], [qw(path)]);
  
  return $path;

}

sub evaluate_template {
  my $self      = shift;
  my $template  = shift;

  my %params    = @_;

  my $r = $self->r;
  my $output;

  $params{params} ||= $self->tpl_params;

  $params{params}->{r} = $r; 
  $params{params}->{notes} = $r->pnotes('combust_notes'); 
  $params{params}->{root} = $root;  # localroot anyone?

  $params{params}->{combust} = $self;

  $params{params}->{site} = $r->dir_config("site")
    unless $params{params}->{site};

  my $user_agent = $r->header_in("User-Agent") || '';
  $params{params}->{user_agent} = $user_agent;
  $params{params}->{ns4_flag} =
    ( $user_agent =~ m!^Mozilla/4!
      && $user_agent !~ m!compatible!
      ? 1
      : 0
    );

  my $rc = $self->tt->process( $template,
			       $params{'params'},
			       \$output )
    or warn( (ref $self ? ref $self : $self) . "  - ". $r->uri . ($r->args ? '?' .$r->args : '')
	     . ' - error processing template ' . $params{'template'} . ': '
	     . $self->tt->error )
      and eval {
	# TODO: throw a "proper" exception?
        die( 'error' => ($@ ? $@ : '') . " " . $self->tt->error );
      };

  delete $params{params}->{combust};

  return \$output;
}

sub site {
  my $self = shift;
  $self->r->dir_config("site")
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
  'iso-8859-1'
}

sub send_output {
  my $self = shift;
  
  # we used to take $r as the first parameter
  if (ref $_[0] eq "Apache::Request") {
    cluck "send_output doesn't need \$r passed anymore"; 
    shift @_;
  }

  my $output = shift;
  my $content_type = shift || $self->content_type || 'text/html';

  unless (defined $output) {
    cluck "send_output called with undefined output";
    return 404;
  }

  # for some reason mod_perl will sometimes forget to dereference
  # a reference, so let's not try printing those anymore.
  $output = $$output if ref $output and ref $output ne 'GLOB';

  my $r = $self->r;

  $self->cookies->bake_cookies;

  # not that we actually have the /w3c/p3p.xml document
  $r->header_out('P3P',qq[CP="NOI DEVo TAIo PSAo PSDo OUR IND UNI NAV", policyref="/w3c/p3p.xml"]);

  my $length;
  if (ref $output eq "GLOB") {
    $length = (stat($output))[7];
  }
  else {
    $length = length($output);
  }

  $r->update_mtime(time) if $r->mtime == 0; 
  
  $r->set_content_length($length);
  $r->set_last_modified();  # set's to whatever update_mtime told us..

  # defining the character set helps in handling the CERT advisory
  # regarding  "cross site scripting vulnerabilities" 
  #   http://www.cert.org/tech_tips/malicious_code_mitigation.html
#  $content_type .= "; charset=" . $self->default_character_set
#    if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
  $content_type .= "; charset=utf-8" if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
  $r->content_type($content_type);
  #warn "content_type: $content_type";

  if ((my $rc = $r->meets_conditions) != OK) {
    # this didn't work with just returning $rc -- need to check if it works now.
    $r->status($rc);
    return $rc;
  }

  $r->send_http_header;

  #warn Data::Dumper->Dump([\$output], [qw(output)]);

  # if all that is requested is HEAD
  # don't send the body
  return OK if $r->header_only;

  if (ref $output eq "GLOB") {
    $r->send_fd($output);
  }
  else {
    $r->print($output);
  }

  # TODO: need to get the status from further up the chain and return it correctly here.
  return OK;
}

sub redirect {
  my $self = shift;
  my $url = shift;
  my $ref_url = ref $url || '';
  $url = shift if $ref_url =~ m/^Apache/;  # if we got passed an $r as the first parameter
  my $permanent = shift;

  $self->cookies->bake_cookies;

  $url = $url->abs if ref $url =~ m/^URI/;

  # this should really check for a complete URI or some such; we'll do
  # that when it breaks on a ftp:// or whatever redirect :-)
  unless ($url =~ m!^https?://!) {
    $url = "http://" . $self->r->hostname .
	  ( $self->config->external_port 
		? ":" . $self->config->external_port
		: ""  )	. $url;
  }

  #use Carp qw(cluck);
  #cluck "redirecting to [$url]";

  $self->r->header_out('Location' => $url);
  $self->r->status($permanent ? MOVED : REDIRECT);

  my $url_escaped = Apache::Util::escape_uri($url);

  my $data = <<EOH;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD><TITLE>302 Found</TITLE></HEAD><BODY><A HREF="$url_escaped">here</A>.<P></BODY></HTML>
EOH

  $self->r->header_out('Content-Length' => length($data));

  $self->r->send_http_header("text/html");
  print $data;
  return DONE;
}

sub cookies {
  my $self = shift;
  my $cookies = $self->request->notes('cookies');
  return $cookies if $cookies;
  $cookies = Combust::Cookies->new($self->request);
  $self->request->notes('cookies', $cookies);
  return $cookies;
}

sub cookie {
  my $self = shift;
  $self->cookies->cookie(@_);
}

sub bitcard {
  my $self = shift;
  my $site = $self->r->dir_config("site");
  require Authen::Bitcard;
  import Authen::Bitcard;
  my $bitcard_token = $self->config->site->{$site}->{bitcard_token};
  my $bitcard_url   = $self->config->site->{$site}->{bitcard_url};
  unless ($bitcard_token) {
    cluck "No bitcard_token configured in combust.conf for $site";
    return;
  }
  my $bc = Authen::Bitcard->new(token => $bitcard_token, @_);
  # $bc->key_cache(sub { &__bitcard_key });
  $bc->bitcard_url($bitcard_url) if $bitcard_url;
  $bc;
}

sub request {
  my $self = shift;
  return $self->{_request} if $self->{_request};
  # should we pass any parameters to the request class when we open it up? Hmn.
  $self->{_request} = $self->request_class->new;
}

my $request_class;
sub request_class {
  return $request_class if $request_class;
  my $class = shift;
  $request_class = $class->pick_request_class;
  eval "require $request_class";
  die qq[Could not load "$request_class": $@] if $@;
  $request_class;
}

sub pick_request_class {
  my ( $class, $request_class ) = @_;

  return 'Combust::Request::' . $request_class if $request_class;
  return "Combust::Request::$ENV{COMBUST_REQUEST_CLASS}" if $ENV{COMBUST_REQUEST_CLASS};

  if ($ENV{MOD_PERL}) {
    my ($software, $version) = $ENV{MOD_PERL} =~ /^(\S+)\/(\d+(?:[\.\_]\d+)+)/;
    if ($software eq 'mod_perl') {
      $version =~ s/_//g;
      $version =~ s/(\.[^.]+)\./$1/g;
      return 'Combust::Request::Apache20' if $version >= 2.000001;
      return 'Combust::Request::Apache13'  if $version >= 1.29;
      die "Unsupported mod_perl version: $ENV{MOD_PERL}";
    }
    else {
      die "Unsupported mod_perl: $ENV{MOD_PERL}"
    }
  }

  return 'Combust::Request::CGI';
}


1;
