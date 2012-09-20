package PerlOrg::Template::Filters;
use strict;

sub navigation_filter_factory {
  my ($context, $uri) = @_;

  return sub {
    my $text = shift;
    return $text unless $uri;
    $uri  =~ s!/?index(?:\.html)?$!/!;

    # why is this here? -- need to write some tests for this... made
    # it work by adding a /? below.
    $uri  =~ s!/$!!; 

    $text =~ s{(<li>)\s*(<a href="\Q$uri\E/?">(.+?)</a>)}{<li class="selected">$2}i;
    return $text;
  }
}

1;
