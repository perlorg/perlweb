#!/usr/bin/perl

use strict;

open(IN, "rfc.tbl") or die "Can't open 'rfc.tbl': $!\n";
chomp(my @rfcs = <IN>);
close(IN);

my $html;
{
	local $/ = undef;
	open(HTML, "rfc.header");
	$html = <HTML>;
	close(HTML);
}

my @rfc_html;
my %rfc_group;
my %rfc_author;
my %class_count;

my $label_attrs = q( align="right" valign="top" );
my $data_attrs =  q( valign="top" );

foreach my $rfc (@rfcs) {
	my @fields = split(/\t/, $rfc);

	$fields[4] =~ s/</\&lt;/g;
	$fields[4] =~ s/>/\&gt;/g;

	$fields[2] =~ s/C<(.*?)>/<code>$1<\/code>/g;
	$fields[2] =~ s/I<(.*?)>/<i>$1<\/i>/g;

	my ($mod, $class);
	$mod = "Last Modified" if $fields[6];
	$class = q( class="retracted") 
		if $fields[7] =~ m/(Retired|Retracted|Withdrawn)/;
	$class = q( class="frozen") if $fields[7] =~ m/Frozen/;

	## Gather counts by type
	$class_count{Retracted}++
		if $fields[7] =~ m/(Retired|Retracted|Withdrawn)/;
	$class_count{Frozen}++
		if $fields[7] =~ m/Frozen/;
	$class_count{Developing}++
		if $fields[7] =~ m/Developing/;

	push (@rfc_html, <<EOHTML);
<p$class>
RFC $fields[0]: <a href="$fields[0].pod">$fields[2]</a> 
[<a href="$fields[0].html">HTML</a>]
<table>
<tr>
 <td $label_attrs<font size="-1"><i>Version</i></font></td>
 <td $data_attrs>$fields[1]</td>
 <td $label_attrs><font size="-1"><i>Maintainer</i></font></td>
 <td $data_attrs>$fields[4]</td>
</tr>
<tr>
 <td $label_attrs><font size="-1"><i>Status</i></font></td>
 <td $data_attrs>$fields[7]</td>
 <td $label_attrs><font size="-1"><i>Mailing&nbsp;List</i></font></td>
 <td $data_attrs>$fields[3]</td>
</tr>
<tr>
 <td $label_attrs><font size="-1"><i>Date</i></font></td> 
 <td $data_attrs>$fields[5]</td>
 <td $label_attrs><font size="-1"><i>$mod</i></font></td>
 <td $data_attrs>$fields[6]</td>
</tr>
</table>
EOHTML

	$fields[3] =~ s/(.*)\@.*$/$1/;
	$fields[3] =~ s/^[^-]+-//;

	$rfc_group{$fields[3]} .= $rfc_html[-1];
	$rfc_author{$fields[4]} .= $rfc_html[-1];
}
my $synopsis = <<"EOHTML";
<p>
<table border=1">
 <tr>
  <th>Status</th>
  <th>Count</th>
 </tr>
 <tr>
  <td>Developing</td>
  <td align="right">$class_count{Developing}</td>
 </tr>
 <tr>
  <td>Frozen</td>
  <td align="right">$class_count{Frozen}</td>
 </tr>
 <tr>
  <td>Retracted</td>
  <td align="right">$class_count{Retracted}</td>
 </tr>
</table>
<p>

EOHTML

my $num = $html;
my $num_html = join("\n", @rfc_html);

$num =~ s/<!--Type-->/Number/g;
$num =~ s/<!--body-->/$synopsis $num_html/g;

open(OUT, ">by-number.html");
print OUT $num;
close(OUT);

my $group = $html;
my $group_links = 
	join (" | ", map {"<a href='#$_'>$_</a>"} sort (keys %rfc_group));
$group =~ s/<!--links-->/<p class="index">[ $group_links ]<\/p>/;

$group =~ s/(<!--body-->)/$synopsis $1/;

foreach (sort keys (%rfc_group)) {
	my $group_html = "<p><hr><p><a name='$_'><h2>$_</h2><p>";
	$group =~ s/(<!--body-->)/$group_html\n$rfc_group{$_}\n$1/;
}
$group =~ s/<!--Type-->/Group/g;

open(OUT, ">by-group.html");
print OUT $group;
close(OUT);

