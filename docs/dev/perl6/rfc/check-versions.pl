#!/usr/bin/perl

use strict;

undef $/;

foreach(1..241) {
	open(F, "$_.pod");
	my $text = <F>;
	close (F);

	$text =~ m/^(.*=head1 VERSION.*?)=head1/s;

	print "[$_]\n$1\n\n";
}

