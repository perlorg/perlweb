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
  shift->{_r};
}

sub req_param {
  my $self = shift;
  $self->r->param(@_);
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
  cluck("tpl_params called with [$self] as self.  Did you configure the handler to call ->handler instead of ->super?") unless ref $self;
  cluck('Combust::Control->tpl_params called with parameters, did you mean to call "param"?') if @_;
  $self->{params} || {};
}

sub _init {
  my ($class, $r) = @_;

  # return if we are already blessed
  return $class if ref $class;

  # pass $r as an Apache::Request
  $r = Apache::Request->instance($r);

  my $self = bless( { _r => $r } , $class);
  
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

  my $self = $class->_init($r);

  my $status;

  eval {
    $status = OK;
    $status = $self->init if $self->can('init');
  };
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
      return $self->send_cached($cache_data);
    }
  }

  ($status, $output, my $content_type) = $self->render;
  return $status unless $status == OK;

  $cache_info->{meta_data}->{content_type} = $content_type if $content_type;
  $cache->store( %$cache_info, data => $output ) if $cache; 
  
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

  $r = Apache::Request->instance($r);

  my $site = $r->dir_config("site");
  unless ($site) {
    my $path = [ $r->document_root ] if $r->dir_config('UseDocumentRoot');
    push @$path, "$root/apache/root_templates/";
    return $path;
  }


  my $site_dir = $config->site->{$site}->{docs_site} || $site;

  #warn Data::Dumper->Dump([\$r], [qw(r)]);

  my $cookies = $r->pnotes('combust_notes')->{cookies};

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

  $params{params}->{site} = $r->dir_config("site");

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

sub content_type {
  my ($self, $content_type) = @_;
  if ($content_type) {
    $self->{_content_type} = $content_type;
  }
  $self->{_content_type};
}

sub send_cached {
  my ($self, $cache, $content_type) = @_;

  $self->r->update_mtime($cache->{created_timestamp});

  $content_type = $cache->{meta_data}->{content_type}
      if $cache->{meta_data}->{content_type};

  return $self->send_output($cache->{data}, $content_type);
}

sub send_output {
  my $self = shift;
  
  # we used to take $r as the first parameter
  if (ref $_[0] eq "Apache::Request") {
    cluck "send_output doesn't need \$r passed anymore"; 
    shift @_;
  }

  my $routput = shift;
  my $content_type = shift || $self->content_type || 'text/html';

  unless (defined $routput) {
    cluck "send_output called with undefined routput";
    return 404;
  }

  $routput = \$routput unless ref $routput;

  my $r = $self->r;

  $r->pnotes('combust_notes')->{cookies}->bake_cookies;

  my $length;
  if (ref $routput eq "GLOB") {
    $length = (stat($routput))[7];
  }
  else {
    $length = length($$routput);
  }

#  if ( $length == 0 ) {
#    my $error = 'zero length output for request: ' . $r->uri . '?' .$r->args;
#    warn( $error );
#    return SERVER_ERROR;
#  }

  #$r->headers_out->{'Content-Length'} = $length;

  $r->update_mtime(time) if $r->mtime == 0; 
  
  $r->set_content_length($length);
  $r->set_last_modified();  # set's to whatever update_mtime told us..

  # defining the character set helps in handling the CERT advisory
  # regarding  "cross site scripting vulnerabilities" 
  #   http://www.cert.org/tech_tips/malicious_code_mitigation.html
  $content_type .= "; charset=utf-8" if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
  $r->content_type($content_type);

  if ((my $rc = $r->meets_conditions) != OK) {
    # this didn't work with just returning $rc -- need to check if it works now.
    $r->status($rc);
    return $rc;
  }

  $r->send_http_header;

  #warn Data::Dumper->Dump([\$routput], [qw(routput)]) if $r->dir_config('site') eq 'cpanratings';

  # if all that is requested is HEAD
  # don't send the body
  return OK if $r->header_only;

  if (ref $routput eq "GLOB") {
    $r->send_fd($routput);
  }
  else {
    # for some reason mod_perl will sometimes forget to dereference the scalar; so we'll just do it here (grumble)
    $r->print($$routput);
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
  # we shouldn't get here without combust_notes, but apparently we do sometimes.
  $self->r->pnotes('combust_notes')->{cookies}->bake_cookies
    if ($self->r->pnotes('combust_notes') and $self->r->pnotes('combust_notes')->{cookies});

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

sub cookie {
  my $self = shift;
  my $r = $self->r;
  my $cookies = $r->pnotes('combust_notes')->{cookies};
  $cookies->cookie(@_);
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
  my $bc = Authen::Bitcard->new(token => $bitcard_token);
  $bc->bitcard_url($bitcard_url) if $bitcard_url;
  $bc;
}

#sub modified_time {
#  my ($self, $new_modified) = @_;
#  my $r = Apache->request;
#  # use $r->update_mtime(..) instead!
#  my $modified = $r->notes('last_modified') || 0;
#  if ($new_modified and $new_modified > $modified) {
#    $r->notes('last_modified', $new_modified);
#  }
#  return $modified;
#} 

1;
