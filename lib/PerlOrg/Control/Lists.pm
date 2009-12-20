# lists.perl.org
package PerlOrg::Control::Lists;
use strict;
use base qw(Combust::Control::Basic);
use Combust::Config;
use JSON qw();
use File::Slurp qw(slurp);
use Combust::Constant qw(OK NOT_FOUND);

# shouldn't we be able to use the object from C::C::Basic?
my $config = Combust::Config->new(); 

my $file = $config->root_docs() . "/lists/data/lists.json";
my $data;
my $next_data = 0;
my $JSON = new JSON();

sub render {
   my $self = shift;

   if (!$data || time() > $next_data) {
     my $rawjson = slurp($file);
     $data ||= $JSON->decode($rawjson);
     $next_data = time() + 5 * 60;
   }

   # all pages get access to list data
   $self->tpl_param( lists => $data );

   # request for a specific list? - special case
   if ($self->request->uri =~ m!^/list/([a-z0-9_.-]+).html!) {
       my $listid = $1;
       if (exists $data->{$listid}) {
           $self->tpl_param( l => $listid );
           my $output = eval { $self->evaluate_template('list.html'); };
           if ($@) {
               $self->request->pnotes('error', $@); 
               return 500;
           }
           return OK, $output, "text/html";
       } else {
           return NOT_FOUND;
       }
   }
   
   # otherwise, treat it as a normal template
   return $self->SUPER::render(@_);
}

1;
