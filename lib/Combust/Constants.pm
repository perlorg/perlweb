package Combust::Constants;
use strict;
use Combust::Request;

my $done = 0;
sub import {
    return if $done;
    Combust::Request->request_class->import_constants;
    $done++; 
}


1;
