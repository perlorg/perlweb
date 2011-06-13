#!/usr/bin/perl

use strict;
use Date::Parse;

undef $/;

my @field_order = map{s/^\s+//; $_} split(/\n/, <<EOLIST);
	Maintainer
	Date
	Last Modified
	Mailing List
	Number
	Version
	Status
EOLIST

sub fix_date($) {
	return unless $_[0];

	my ($d, $m, $y) = (strptime($_[0]))[3..5];
	my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
	$d = int($d);
	$m = $months[$m];
	$y += 1900;

	"$d $m $y";
}


foreach my $file (<*.pod>) {
	open (POD, $file);
	my $pod = <POD>;
	close(POD);

	my ($meta) = $pod =~ m/=head1\s+VERSION\s+(.*?)=head1/s;

	$meta =~ s/^\s+//smg;

	my %fields = map {split(/:\s+/, $_, 2)} split(/\n/, $meta);

	## Be explicit about status
	$fields{Status} = "Developing" unless $fields{Status};

	## Correct spelling
	if ($fields{"Last-Modified"}) {
		$fields{"Last Modified"} = $fields{"Last-Modified"};
		delete $fields{"Last-Modified"};
	}

	$fields{"Last Modified"} = fix_date($fields{"Last Modified"});
	$fields{Date} = fix_date($fields{Date});

	$fields{Version} = int($fields{Version});

	$meta = '';

	## Standard fields in standard order
	foreach (@field_order) {
		next unless $fields{$_};
		$meta .= "  $_: $fields{$_}\n";
	}

	## Ignore the standard fields, move onto other fields.
	delete @fields{@field_order};

	foreach (sort keys(%fields)) {
		$meta .= "  $_: $fields{$_}\n";
	}

	$pod =~ s/(=head1\s+VERSION).*?(=head1)/\1\n\n$meta\n$2/s;
	open (POD, ">$file");
	print POD $pod;
	close(POD);
}
