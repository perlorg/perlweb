package Combust::Template::Filters;
use strict;

sub navigation_filter_factory {
  my ($context, $uri, $pre, $post) = @_;

  $pre  ||= '&raquo; ';
  $post ||= ' &laquo;'; 

  #warn "Filter Factory Called!";

  return sub {
    my $text = shift;
    #warn "FILTER called!";
    return $text unless $uri;
    #warn "URI1: $uri";
    $uri  =~ s!/?index(?:\.html)?$!/!;
    $uri  =~ s!/$!!;
    #warn "URI2: $uri";
    $text =~ s{(?:&nbsp;&nbsp;)?\s*<a href="\Q$uri\E">(.+?)</a>}{$pre$1$post}i;
    return $text;
  }
}


1;
