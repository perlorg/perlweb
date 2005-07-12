package Combust::Template::Filters;
use strict;

sub navigation_filter_factory {
  my ($context, $uri, $pre, $post) = @_;

  $pre  ||= '&raquo; ';
  $post ||= ' &laquo;'; 

  #warn "Filter Factory Called!";

  return sub {
    my $text = shift;
    return $text unless $uri;
    $uri  =~ s!/?index(?:\.html)?$!/!;

    # why is this here? -- need to write some tests for this... made
    # it work by adding a /? below.
    $uri  =~ s!/$!!; 

    $text =~ s{(?:&nbsp;&nbsp;)?\s*<a href="\Q$uri\E/?">(.+?)</a>}{$pre$1$post}i;
    return $text;
  }
}


1;
