package Develooper::TemplateFiller;
use strict;
use Text::Template;   
use Exporter;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(template_filler);

sub template_filler {
  my %p = @_;
  my $template = new Text::Template (%{$p{new}})
    or die "Couldn't make template: $Text::Template::ERROR; aborting";
  
  $template->fill_in(OUTPUT  => \*STDOUT,
                     PACKAGE => "T", 
                     HASH    => { 
                                 $p{hash} ? %{$p{hash}} : ()
                                },
                     $p{fill_in} ? %{$p{fill_in}} : ()
                    );
}


1;
