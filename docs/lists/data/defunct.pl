#!/usr/bin/perl

use JSON;
use File::Slurp qw(slurp);
use strict;

# Helper script used to mark lists as defunct.
#
# Input: reads from lists.json
# Output: writes to stdout
#
# Usage:
#  ./defunct.pl $(cat DISABLED | xargs) > lists.json.new

my $data  = from_json(slurp("lists.json"));

for my $list (@ARGV) {
  $list =~ s/^perl-//;
  if (exists $data->{$list}) {
    $data->{$list}{defunct} = "1";
  } elsif (exists $data->{"perl-$list"}) {
    $data->{"perl-$list"}{defunct} = "1";
  } else {
    warn "$list not found\n";
  }
}

my $json = new JSON;
$json->canonical(1); # sort keys
print $json->pretty->encode($data);
