#!/usr/bin/perl -w

use strict;
use Date::Parse;

################

my @rfcs = get_rfcs();
my $today = int(time / 86400);
my $html_template = get_template();

my $developing = 0;
my $overdue = 0;
my $submissions = 0;

$html_template =~ s/<!--datestamp-->/gmtime() . " GMT"/es;

################

sub get_template() {
	local $/ = undef;
	return <DATA>;
}

sub get_rfcs() {
	open(IN, "rfc.tbl") or die "Can't open 'rfc.tb.': $!\n";
	chomp (my @rfcs = <IN>);
	@rfcs;
}

sub rfc_report(@) {
	my ($num, $ver, $title, $mlist, $maint, $date, $mod, $status) = @_;

	$title =~ s/C<(.*?)>/<code>$1<\/code>/g;
	$title =~ s/I<(.*?)>/<i>$1<\/i>/g;

	$mod = " Last Mod: $mod" if $mod;

	return 
"RFC  : $num, v$ver: $status
Title: <a href='$num.html'>$title</a>
Date : $date$mod";
}

sub overdue_by_author(\%) {
	my $authors = shift;
	my $body = <<EOT;
<p>
<h2>Overdue RFCs by Maintainer</h2>
<table border='1' cellspacing='1' cellpadding='0'>
EOT

	my @authors = sort {$authors->{$b} <=> $authors->{$a}} keys %$authors;
	my $total = 0;
	foreach (@authors) {
		$body .= "<tr><td>$_</td><td>$authors->{$_}</td></tr>\n";
		$total += $authors->{$_};
	}
	$body .= "<tr><th>Total</th><td>$total</td></tr>\n";
	$body .= "</table>";

	$body;
}

sub make_master(\@\%\%) {
	my $aref = shift();
	my $groups = shift();
	my $authors = shift();

	my $html = $html_template;

	my @order = sort {($b->[0] <=> $a->[0]) or ($a->[1] cmp $b->[1])} 
		map {[int @{$groups->{$_}}, $_]} @$aref;

	my $body = "<ul>";

	foreach (@order) {
		$body .= "<li><a href='overdue-$_->[1].html'>$_->[1]</a>: " .
			"$_->[0] RFCs</li>\n";

			# Sep-29-2000: Mark all non-final RFCs as overdue
			#"$_->[0] RFCs overdue</li>\n";
	}

	$body .= "</ul>";

	$body .= overdue_by_author(%$authors);

	$html =~ s|<!--body-->|$body|s;

	my $status = <<EOT;
<p>
$submissions RFCs submitted.
<br>
$developing RFCs in development.
<!--
<br>
$overdue RFCs not updated within the last 7 days.
<p>
-->
EOT
	$html =~ s|<!--status-->|$status|s;

	open(OUT, ">overdue.html");
	print OUT $html;
	close(OUT);
}

sub make_page($$) {
	my $list = shift();
	my $aref = shift();
	my $html = $html_template;
	my %author_count;
	my $body = <<EOT;


<table border="1" cellspacing="1" cellpadding="1">
 <tr>
  <th>Maintainer</th>
  <th>Days since last update</th>
  <th>RFC</th>
 </tr>
EOT

	my @elements = sort {($b->[0] <=> $a->[0]) or ($a->[1] cmp $b->[1])} 
		@$aref;

	foreach (@elements) {
		my ($days, $maint, $block) = @$_;
		$days = "<font color='red'>$days</font>" if $days > 14;

		$body .= <<EOT;
<tr>
 <td align="center" valign="top">$maint</td>
 <td align="center" valign="top">$days</td>
 <td><pre>$block</pre></td>
</tr>
EOT

		$author_count{$maint}++;
	}
	$body .= "</table>\n";

	$body .= overdue_by_author(%author_count);

	$html =~ s|<!--list-->|$list|sg;
	$html =~ s|<!--body-->|$body|s;

	open(OUT, ">overdue-$list.html");
	print OUT $html;
	close(OUT);
}

################

my %rfc_groups;
my %rfc_authors;

foreach my $rfc (@rfcs) {
	my @fields = split(/\t/, $rfc);
	my ($mlist, $maint, $date, $mod, $status) = @fields[3..7];

	$submissions++;

	next unless $status eq "Developing";

	$developing++;

	## Use Last Modified if there, else use posting date.
	my $mod_date = int(str2time($mod or $date) / 86400);
	my $age = $today - $mod_date;

	## Stop now if this RFC has been touched within the last week
        ## 
	## Sep-29-2000:
	##   Mark all RFCs as overdue; the deadline is nigh!
	# next if $age <= 7;

	$overdue++;

	## Prepare a report entry for this RFC
	my $block = rfc_report(@fields);

	$mlist =~ s/\@.*$//;
	$maint =~ s/</\&lt;/g;
	$maint =~ s/>/\&gt;/g;

	push (@{$rfc_groups{$mlist}}, [$age, $maint, $block]);

	$rfc_authors{$maint}++;
}

my @groups = sort keys %rfc_groups;

make_master(@groups, %rfc_groups, %rfc_authors);
make_page($_, $rfc_groups{$_}) foreach(@groups) 

__DATA__
<html>
<head>
 <title>Perl6 RFCs: Overdue RFCs: <!--list--></title>
</head>

<body bgcolor="white" link="#690020" alink="#003600" vlink="#900000">

<style rel="styleSheet" type="text/css">

 body  { 
 	color: black; 
	font-size: 12pt; 
	font-family: Verdana, Helvetica, Arial
 }

 th  { 
 	color: black; 
	font-size: 12pt; 
	font-family: Verdana, Helvetica, Arial
 }

 td  { 
 	color: black; 
	font-size: 10pt; 
	font-family: Verdana, Helvetica, Arial
 }

 H1 { 
 	color: black;  
	font-size: 18pt; 
	font-weight: bold; 
	font-family: Helvetica, Arial 
 }

 H2 { 
 	color: black;  
	font-size: 14pt; 
	font-weight: bold; 
	font-family: Helvetica, Arial
 }

 H3 { 
 	color: black; 
	font-weight: bold; 
	font-family: Helvetica, Arial
 }

 .smallsmallsmall { font-size: 20% }

 .tt        { color: black; font-family: Courier } 

 .frozen { background-color: #8888ff }
 .retracted { background-color: #ff8888 }
 .index { font-size: 10pt; align: center }

 .warning {background-color=blue; color=yellow;}
 .crufty { background-color=red; color=white; }

</style>

<h1>Perl6 RFCs: Overdue RFCs <!--list--></h1>

<!--links-->

<p>

Report generated: <!--datestamp-->

<!--status-->

<!--body-->

</body>
</html>
