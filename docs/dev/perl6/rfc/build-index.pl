#!/usr/bin/perl

use strict;
use Date::Parse;

sub fix_date($) {
	return unless $_[0];

	my ($d, $m, $y) = (strptime($_[0]))[3..5];
	my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
	$d = int($d);
	$m = $months[$m];
	$y += 1900;

	"$d $m $y";
}

undef $/;

my @rfcs;

foreach my $pod (<*.pod>) {
	open(F, $pod);
	my $text = <F>;
	close(F);

	my ($title) = $text =~ m/=head1\s+TITLE\s+(.*?)\s+=head/sm;
	$title =~ s/\n/ /g;

	($text) = $text =~ m/=head1\s+VERSION\s+(.*?)\s+=head/sm;
	$text =~ s/\n\s+/\n/smg;

	my %fields = map {split(/:\s+/, $_)} split(/\n/, $text);
	$fields{Title} = $title;
	$fields{Status} = "[Developing]" unless $fields{Status};
	$fields{Mail} = $fields{"Mailing List"};
	$fields{Last} = $fields{"Last Modified"} || $fields{"Last-Modified"};

	$fields{Date} = fix_date($fields{Date});
	$fields{Last} = fix_date($fields{Last});

	$fields{Mail} =~ s/\s//g;

	$rfcs[$fields{Number}] = \%fields;
}

open(OUT, ">rfc.tbl");

foreach my $rfc (@rfcs) {
	next unless $rfc->{Number}; ## Skip RFC 0

	print OUT join("\t", @$rfc{qw( 
		Number Version Title Mail Maintainer Date Last Status
	)}), "\n";

}

close(OUT);

