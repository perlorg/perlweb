#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

my $HOME="/home/httpd/tmtowtdi.perl.org";

open(F, "summary.txt");
my @summary_list = <F>;
chomp(@summary_list);
close(F);

$/ = "\n\n";
open(F, "$HOME/working-groups.txt");
my @groups = <F>;
close(F);

undef $/;

open(F, "index.tmpl");
my $index = <F>;
close(F);


######

my (%summaries, @items);
foreach(@summary_list) {
	@items = split("\t", $_);
	$summaries{$items[0]}{$items[1]} = $items[2];
	$summaries{$items[0]}{count}++;
}

my $group;
my $html;
my $group_count = 0;

foreach (@groups) {
	($group) = m/(?:WORKING GROUP|LIST):\s+(.*)\s*$/m;

	next unless $group;

	($summaries{$group}{chair})    = m/CHAIR:\s+(.*)\s*$/m;
}


### (1) Emit all summaries with statuses
foreach $group (sort keys %summaries) {
	next unless $summaries{$group}{count};

	$html .= "</p><hr width='50%'>\n" if $group_count;

	my $href = $summaries{$group};
	my $bold = 1;

	my $chair = $href->{chair}; delete $href->{chair};
	$chair =~ s/</\&lt;/;
	$chair =~ s/>/\&gt;/;

	$html .= "<p><b>$group</b> <i>Chair:</i> $chair<br>\n";

	delete $href->{count};

	foreach(reverse sort keys (%$href)) {
		my ($y, $m, $d) = unpack("a4a2a2", $_);
		$m--; $y -= 1900;
		my $date = strftime("%b %d %Y", 0, 0, 0, $d, $m, $y);
		

		$html .= "<b>" if $bold;
		$html .= "<a href=\"$href->{$_}\">$date</a>";
		$html .= "</b>" if $bold;
		$html .= " ";
		$bold = 0;
	}

	$group_count++;
	delete $summaries{$group};
}

$html .= "</p><hr>\n";

$html .= "<h2>No Summary Available</h2>\n";

## 2) Emit all groups w/o summaries
foreach $group (sort keys %summaries) {
	my $href = $summaries{$group};
	my $bold = 1;

	my $chair = $href->{chair}; delete $href->{chair};
	$chair =~ s/</\&lt;/;
	$chair =~ s/>/\&gt;/;

	$html .= "<p><b>$group</b> <i>Chair:</i> $chair</p>\n";
}


$index =~ s/<!--BODY-->/$html/;

open(F, ">index.html");
print F $index;
close(F);
