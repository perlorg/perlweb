#!perl
# Generates index.html
use strict;
use warnings;
open my $index, '>', 'index.html' or die "Can't open index.html: $!\n";
print $index <<'**HEAD**';
[% page.title = "Perl5 List Summaries" %]

By Scott Lanning

<UL>
**HEAD**
for my $pod (sort {$b cmp $a} <*/*.pod>) {
    open my $fh, '<', $pod or die "Can't read $pod: $!\n";
    my $head = <$fh>;
    close $fh;
    if ($head !~ /^=head1 Th[ie]se? (?:Week|Month)s? on perl5-porters \((.*)\)/i) {
	warn "$pod malformed\n";
	next;
    }
    else {
	my $date = $1;
	$pod =~ s/pod$/html/;
	print $index <<"**HTML**";
<LI><A HREF="$pod">$date</A>
**HTML**
    }
}
print $index "</UL>\n";
close $index;
__END__
