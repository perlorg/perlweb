package Combust::Control;
use strict;
use Exception::Class ('ControllerException');
use Apache::Request;
use Apache::Cookie;
use Apache::Constants qw(:common :response );
use Apache::File;

use Template;
use Template::Parser;

use Combust::Template::Provider;
use Combust::Template::Filters;

#use HTTP::Date qw(time2str); 

$Template::Config::STASH = 'Template::Stash::XS';

my $parser = Template::Parser->new(); 

my %provider_config = (
		       PARSER => $parser,
		       'COMPILE_EXT'    => '.ttc',
		       'COMPILE_DIR'    => "$ENV{CBROOT}/tmp/ctpl",
		       #TOLERANT => 1,
		       RELATIVE => 1,
		       'CACHE_SIZE'     => 128,  # cache all templates
		      );

#my $file = Template::Provider->new(%provider_config, 
#				   INCLUDE_PATH => "$ENV{CBROOT}/docs/www/live", 
#				  );

#my $http = Combust::Template::Provider::SVN->new(
#				      %provider_config,
#				      INCLUDE_PATH => ['http://svn.develooper.com/perl.org/docs/www'],
#				     );

# use Combust::Template::Provider some day ...
my $combust_provider = Template::Provider->new
  (
   %provider_config,
   INCLUDE_PATH => [
		    sub {
                      my $r = Apache->request;
 		      [ "$ENV{CBROOT}/docs/live/" . $r->dir_config("site") ];
		    },
		    "$ENV{CBROOT}/docs/live/shared/",
		    "$ENV{CBROOT}/docs/live/",
		    #'http://svn.develooper.com/perl.org/docs/www/live',
		   ],
  );


my $tt = Template->new
  ({
    FILTERS => { 'navigation' => [ \&Combust::Template::Filters::navigation_filter_factory, 1 ] },
    RELATIVE       => 1,
    LOAD_TEMPLATES   => [$combust_provider],
    #'LOAD_TEMPLATES' => [ $file, $http ],
    #PREFIX_MAP => {
    #               file => 0,
    #               http => 1,
    #		    default => 1,
    #	            },
    'PRE_PROCESS'    => 'tpl/defaults',
    'PROCESS'        => 'tpl/wrapper' ,
   });

sub evaluate_template {
  my $class     = shift;
  my $r         = shift;
  my %params    = @_;

  $params{params}->{r} = $r; 
  $params{params}->{notes} = $r->pnotes('combust_notes'); 

  #$params{params}->{statistics}    = XRL::Statistics->new();
  #$params{params}->{advertisement} = XRL::Advertisement->new();

  my $rc = $tt->process( $params{'template'},
                         $params{'params'},
                         $params{'output'} )
    or warn( "$class - ". $r->uri . '?' .$r->args
	     . ' - error processing template ' . $params{'template'} . ': '
	     . $tt->error )
      and eval {
        ControllerException->throw( 'error' => $tt->error );
      };
  
  $rc;
}


sub send_output {
  my $class   = shift;
  my $r       = shift;
  my $routput = shift;
  my $content_type = shift || 'text/html';
  
  $r->pnotes('combust_notes')->{cookies}->bake_cookies;

  my $length = length($$routput);
  if ( $length == 0 ) {
    my $error = 'zero length output for request: ' . $r->uri . '?' .$r->args;
    warn( $error );
    return SERVER_ERROR;
  }
  
  #$r->headers_out->{'Content-Length'} = $length;
  $r->set_content_length($length);
  $r->set_last_modified();  # set's to whatever update_mtime told us..
  #$r->set_last_modified($class->modified_time || time);
  #$r->header_out('Last-Modified', );

  # defining the character set helps in handling the CERT advisory
  # regarding  "cross site scripting vulnerabilities" 
  #   http://www.cert.org/tech_tips/malicious_code_mitigation.html
  $r->content_type("$content_type; charset=iso-8859-1");

  if ((my $rc = $r->meets_conditions) != OK) {
    return $rc;
  }

  $r->send_http_header;

  # if all that is requested is HEAD
  # don't send the body
  return OK if $r->header_only;

  $r->print($$routput);
  return OK;
}

sub redirect {
  my $self = shift;
  my $r   = shift;
  my $url = shift;
  $r->pnotes('combust_notes')->{cookies}->bake_cookies;
  $r->header_out('Location', $url);
  return REDIRECT;
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
