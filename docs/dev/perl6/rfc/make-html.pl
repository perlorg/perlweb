#!/usr/bin/perl

use strict;

foreach my $pod (<*.pod>) {
	my $html = $pod;
	$html =~ s/pod$/html/;

	if ((! -e $html) || (-M $pod < -M $html)) {
		print "$pod -> $html\n";
		`pod2html $pod > $html`;
	}
}
