use lib "$ENV{CBROOT}/lib";

use Template;
use Template::Parser;

use Combust::Template::Provider;

$Template::Config::STASH = 'Template::Stash::XS';

my $parser = Template::Parser->new(); 

my %provider_config = (
		       PARSER => $parser,
		       'COMPILE_EXT'    => '.ttc',
		       'COMPILE_DIR'    => "$ENV{CBROOT}/tmp/ctpl",
		       TOLERANT => 1,
		      );

my $file = Template::Provider->new(%provider_config, 
				   INCLUDE_PATH => "$ENV{CBROOT}/tpl", 
				  );

#my $http = Combust::Template::Provider::SVN->new(
#				      %provider_config,
#				      INCLUDE_PATH => ['http://svn.develooper.com/perl.org/docs/www'],
#				     );


my $combust_provider = Combust::Template::Provider->new
  (
   %provider_config,
   INCLUDE_PATH => ['http://svn.develooper.com/perl.org/docs/www/live',
		    "$ENV{CBROOT}/docs/www/live",
		   ],
  );


my $tt = Template->new
  ({
    #'PLUGIN_BASE'    => 'Util::Template::Plugin',
    #'PLUGINS'        => { },
    'RELATIVE'       => 1,
    LOAD_TEMPLATES   => [$combust_provider],
    #'LOAD_TEMPLATES' => [ $file, $http ],
    #PREFIX_MAP => {
    #               file => 0,
    #               http => 1,
    #		    default => 1,
    #	            },
    #'EVAL_PERL'      => 1,
    #'PRE_PROCESS'    => 'datadefs',
    'CACHE_SIZE'     => undef,  # cache all templates
    'COMPILE_EXT'    => '.ttc',
    'COMPILE_DIR'    => "$ENV{CBROOT}/tmp/ctpl",
    #'PROCESS'        => 'config/set_mtime' ,
   });

my %params;
$params{template} = "test.html";
$params{params} = { test => "foo" };

for (1..2) {
my $rc = $tt->process( $params{'template'},
		       $params{'params'},
		       $params{'output'} )
  or warn "error processing template $params{template}: " . $tt->error;

print $params{output} if $params{output};
}
