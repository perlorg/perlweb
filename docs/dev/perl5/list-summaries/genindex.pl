#!perl
# Generates index.html
use strict;
use warnings;

use Date::Calc;

open my $index, '>', 'index.html' or die "Can't open index.html: $!\n";
open my $rss, '>', 'index.rss' or die "Can't open index.rss: $!\n";
print $index <<'**HEAD**';
[% page.title = "Perl5 List Summaries" %]

<UL>
**HEAD**
print $rss <<'**HEAD**';
 <rss version="0.91">
  <channel>
    <title>Perl5 List Summaries</title>
    <link>http://dev.perl.org/perl5/list-summaries/</link>
    <description>Weekly summaries of what's going on in and around Perl5.</description>
    <language>en-us</language>
**HEAD**
my $i=0;
for my $pod (sort {$b cmp $a} <*/*.pod>) {
    $i++;
    open my $fh, '<', $pod or die "Can't read $pod: $!\n";
    my $head = <$fh>;
    close $fh;
    if ($head !~ /^=head1 Th[ie]se? (?:Week|Month)s? on perl5-porters +-? *(.*)/i) {
	warn "$pod malformed\n";
	next;
    }
    else {
	my $date = $1;
	$date =~ s/^\(\s*//;
	$date =~ s/\s*\)$//;
	$pod =~ s/pod$/html/;
	print $index <<"**HTML**";
<LI><A HREF="$pod">$date</A>
**HTML**
    print $rss <<"**RSS**" unless $i > 10;
<item>
  <title>Perl 5 Summary for $date</title>
  <description>Perl 5 Summary for $date</description>
  <link>http://dev.perl.org/perl5/list-summaries/$pod</link>
</item>
**RSS**
    }
}
print $index "</UL>\n";
print $rss <<'**FOOT**';
</channel>
</rss>
**FOOT**
close $index;

__END__
