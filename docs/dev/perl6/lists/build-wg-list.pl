#!/usr/bin/perl -w
use strict;

#
# build html list of working groups from working-groups.txt
#

open TXT, "working-groups.txt" or die "Could not open working-groups.txt: $!";
open HTML, ">working-groups.html" or die "Could not open working-groups.txt: $!";
#*HTML = *STDOUT;

my %wg;

my $current = "";
my $section = "";

$| = 1;

while (<TXT>) {

  s/^\s*//;

  # shold so some real escaping fun here ...
  s/</&lt;/;
  s/>/&gt;/;

  chomp;

  if (m/^\[([^\]]+)\]/) {
	$section = $1;
	next;
  }

  if (m/^\s*$/) {
	next unless %wg;
	generate_wg_html(\%wg);
	%wg = ();
	$current = "";	
  }

  if (m/^([A-Z\s]+):\s+(.*)/) {
	$current = lc $1;
	$current = "working group" if $current eq "list";
	$wg{$current} = $2;
 	if ($current eq "working group") {
      $wg{$current} =~ s/\s+$//;
      $wg{$current} =~ s/\@perl\.org//;
	}	
  } else {
	next unless $current;
	$wg{$current} .= " $_";
  }

}

sub generate_wg_html {
  my $wg = shift;

  my $wg_name = $wg{"working group"} or die "missing working group name somewhere...";

  print HTML qq[<dt><a name="$wg_name"><b>$wg_name</b></a>];
  print HTML qq[ <i>(closed)</i>] if $section eq "closed";

  print HTML qq[\n<dd>];

  for my $part ("mission") {
	die "$wg_name missing section $part!" unless $wg->{$part};
	my $part_print = $part; $part_print =~ s/(.)/\U$1/;
	print HTML qq[$part_print: $wg->{$part}<br>\n];
	delete $wg->{$part};
  }

  print HTML "Description: $wg->{description}<br>\n"
	if $wg->{description};

  # here we should probably print any additional sections ...

  print HTML qq[Subscribe: <a href="mailto:$wg_name-subscribe\@perl.org">$wg_name-subscribe\@perl.org</a> - \n]
	unless $section eq "closed";
  print HTML qq[<a href="http://archive.develooper.com/$wg_name%40perl.org/">Archive</a>\n<p>\n];
}


