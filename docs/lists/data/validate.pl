#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use File::Slurp qw(slurp);
use Getopt::Long;
GetOptions ("dump|d" => \my $dump_output);


my $data  = from_json(slurp($ARGV[0]||"lists.json"));

if ($dump_output) {
    my $json = new JSON;
    $json->canonical(1); # sort keys
    print $json->pretty->encode($data);
}

