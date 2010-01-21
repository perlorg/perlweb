# lists.perl.org
package PerlOrg::Control::Lists;
use strict;
use base qw(Combust::Control::Basic);
use Combust::Config;
use JSON qw();
use File::Slurp qw(slurp);
use HTML::TagCloud;

use Combust::Constant qw(OK NOT_FOUND);

# TODO: move tag.html and list.html to .tpl files
# TODO: fix indentation
# TODO: add tags validation to validate.pl or fixup.pl

# shouldn't we be able to use the object from C::C::Basic?
my $config = Combust::Config->new(); 

my $file = $config->root_docs() . "/lists/data/lists.json";
my $data;
my $next_data = 0;
my $JSON = new JSON();
my $tagcloud; # html tagcloud
my $tagmap;   # tag -> [lists]

sub render {
   my $self = shift;

   if (!$data || time() > $next_data) {
     my $rawjson = slurp($file);
     $data = $JSON->decode($rawjson);
     $next_data = time() + 5 * 60;
     $self->tagcloud($data);
   }

   # all pages get access to list data
   $self->tpl_param( lists => $data );
   $self->tpl_param( tagcloud => $tagcloud );
   $self->tpl_param( tagmap => $tagmap );

   if ($self->request->uri =~ m!^/showlist\.cgi!) {
       my $list = $self->req_param("name");
       $list =~ s/[^A-Za-z0-9_-]//g;
       return $self->redirect("/list/" . $list . ".html" ) if $list;
   }

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
   elsif ($self->request->uri =~ m!^/tag/(\w+).html!) {
       my $tag = $1;
       if (exists $tagmap->{$tag}) {
           $self->tpl_param( tag => $tag );
           my $output = eval { $self->evaluate_template('tag.html'); };
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

sub tagcloud {
  my ($self, $lists) = @_;

  $tagmap = {};

  for my $list (keys %{$lists}) {
    my @tags = grep { /^\w*$/; }
      map {
        # normalize
        s/^\s+//s;
        s/\s+$//s;
        lc $_;
      } split(/,/, $lists->{$list}{"tags"});
    for my $t (@tags) {
      if (!exists $tagmap->{$t}) {
        $tagmap->{$t} = [$list];
      } else {
        push @{$tagmap->{$t}}, $list;
      }
    }
    # replace unparsed with parsed
    $lists->{$list}{"tags"} = [@tags];
  }

  my $cloud = HTML::TagCloud->new;
  for my $tag (keys %{$tagmap}) {
    $cloud->add($tag, "/tag/$tag.html", scalar @{$tagmap->{$tag}});
  }
  $tagcloud = $cloud->html();
}

1;
