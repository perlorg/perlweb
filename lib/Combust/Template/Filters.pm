package Combust::Template::Filters;
use strict;

sub navigation_filter_factory {
  my ($context, $uri) = @_;

  warn "Filter Factory Called!";

  return sub {
    my $text = shift;
    warn "FILTER called!";
    return $text unless $uri;
    warn "URI1: $uri";
    $uri  =~ s!(/?index(?:\.html)?|/)$!!;
    warn "URI2: $uri";
    $text =~ s{&nbsp;&nbsp;\s+<a href="\Q$uri\E">(.+?)</a>}{&raquo; $1 &laquo;}i;
    return $text;
  }
}


1;
