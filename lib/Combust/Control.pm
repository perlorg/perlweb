package Combust::Control;
use strict;
use Exception::Class ('ControllerException');
use Apache::Request;
use Apache::Cookie;
use Apache::Constants qw(:common :response );
use Apache::File;

use Template;
use Template::Parser;
use Template::Stash;

use Combust::Template::Provider;
use Combust::Template::Filters;

use Combust::Template::Translator::POD;

use Combust::Config;

my $config = Combust::Config->new();

sub config { $config }

#use HTTP::Date qw(time2str); 

$Template::Config::STASH = 'Template::Stash::XS';

$Template::Stash::SCALAR_OPS->{ rand } = sub {
  return int(rand(shift));
    };

my $parser = Template::Parser->new(); 

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
   });

sub provider {
  $Combust::Control::provider;
}

sub tt {
  $Combust::Control::tt
}

sub r {
  shift->{_r};
}

sub param {
  my ($self, $key) = (shift, shift);
  return unless $key;
  $self->{params}->{$key} = shift if @_;
  return $self->{params}->{$key};
}

sub params {
  shift->{params};
}

sub super($$) {
  my $class   = shift;
  my $r = shift;

  use Carp qw(confess);
  confess(__PACKAGE__ . '->super got called without $r') unless $r;
  return unless $r;

  # pass $r as an Apache::Request
  $r = Apache::Request->new($r);

  my $self = bless( { _r => $r } , $class);
  
  $self->{params} = {
    config => $config,
  };

  my $status;
  eval {
    $status = $self->handler($r);
  };
  warn "Combust::Control: oops, class handler died with $@" if $@;
  
  return $status;
}

sub get_include_path {
  my $r = Apache->request;

  $r = Apache::Request->instance($r);

  my $site = $r->dir_config("site");

  #warn Data::Dumper->Dump([\$r], [qw(r)]);

  my $cookies = $r->pnotes('combust_notes')->{cookies};

  #warn "param:root: ", $r->param('root');
  #warn "root coookie : ", $cookies->cookie('root');

  my ($user, $dir);
  if (($user, $dir) = ($r->param('root') =~ m!^/?([a-zA-Z]+)/([^\.]+)$!)) {
    # FIXME|TODO: should expand on ~ instead of using /home
    #$root = "/home/$user/docs/$dir/$site";
    $cookies->cookie('root', "$user/$dir");
  } 
  elsif ($r->param('root') eq "/") {
    # don't set user and dir, reset the cookie
    $cookies->cookie('root', "/");
  }
  elsif (($user, $dir) = ($cookies->cookie('root') =~ m!^([a-zA-Z]+)/([^\.]+)$!)) {
    #warn "got root cookie";
    #$root = "/home/$user/docs/$dir/$site";
  }

  $r->pnotes('combust_notes')->{include_root} = ($user and $dir) ? "/$user/$dir" : '/';

  my $path;

  my $docs = $config->docs_name;

  if ($user and $dir) {
    $user = "/home/$user";
    $path = [
	     "$user/$docs/$dir/$site/",
	     "$user/$docs/$dir/shared/",
	     "$user/$docs/$dir/",
	    ];
  }
  else {
    my $root_docs = $config->root_docs,
    # TODO: root=/something should set dir to 'something'
    $dir = 'live';
    $path = [
	     "$root_docs/$dir/$site/",
	     "$root_docs/$dir/shared/",
	     "$root_docs/$dir/",
	    ];
  }

  #warn Data::Dumper->Dump([\$path], [qw(path)]);
  
  return $path;

}

my $root = $ENV{CBROOT};

sub evaluate_template {
  my $class     = shift;
  my $r         = shift;
  my %params    = @_;

  $params{params}->{r} = $r; 
  $params{params}->{notes} = $r->pnotes('combust_notes'); 
  $params{params}->{root} = $root;

  #$params{params}->{statistics}    = XRL::Statistics->new();
  #$params{params}->{advertisement} = XRL::Advertisement->new();

  my $rc = $class->tt->process( $params{'template'},
                         $params{'params'},
                         $params{'output'} )
    or warn( "$class - ". $r->uri . ($r->args ? '?' .$r->args : '')
	     . ' - error processing template ' . $params{'template'} . ': '
	     . $class->tt->error )
      and eval {
        ControllerException->throw( 'error' => $class->tt->error );
      };
  
  $rc;
}


sub send_cached {
  my ($class, $r, $cache, $content_type) = @_;

  $r->update_mtime($cache->{created_timestamp});

  $content_type = $cache->{meta_data}->{content_type}
      if $cache->{meta_data}->{content_type};

  return $class->send_output($r, $cache->{data}, $content_type);
}

sub send_output {
  my $class   = shift;
  my $r       = shift;
  my $routput = shift;
  my $content_type = shift || 'text/html';
  
  $r->pnotes('combust_notes')->{cookies}->bake_cookies;

  $routput = $$routput if ref $routput;

  my $length;
  if (ref $routput eq "GLOB") {
    $length = (stat($routput))[7];
  }
  else {
    $length = length($routput);
  }

  if ( $length == 0 ) {
    my $error = 'zero length output for request: ' . $r->uri . '?' .$r->args;
    warn( $error );
    return SERVER_ERROR;
  }

  #$r->headers_out->{'Content-Length'} = $length;

  $r->update_mtime(time) if $r->mtime == 0; 
  
  $r->set_content_length($length);
  $r->set_last_modified();  # set's to whatever update_mtime told us..

  # defining the character set helps in handling the CERT advisory
  # regarding  "cross site scripting vulnerabilities" 
  #   http://www.cert.org/tech_tips/malicious_code_mitigation.html
  $content_type .= "; charset=iso-8859-1" if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
  $r->content_type($content_type);

  if ((my $rc = $r->meets_conditions) != OK) {
    return $rc;
  }

  $r->send_http_header;

  # if all that is requested is HEAD
  # don't send the body
  return OK if $r->header_only;

  if (ref $routput eq "GLOB") {
    $r->send_fd($routput);
  }
  else {
    $r->print($routput);
  }

  return OK;
}

sub redirect {
  my $self = shift;
  my $r   = shift;
  my $url = shift;
  my $permanent = shift;
  $r->pnotes('combust_notes')->{cookies}->bake_cookies;

  unless ($url =~ m!^http://!) {
    $url = "http://" . $r->hostname . $url; 
  }

  $r->header_out('Location', $url);
  return $permanent ? MOVED : REDIRECT;
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
