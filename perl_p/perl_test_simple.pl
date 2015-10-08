#!/usr/bin/perl
#
use strict;
use warnings;

use Test::Simple "no_plan";

#read calc 
my $fileCalc = "calc.txt";
open(my $fh, "<$fileCalc") or die "open file $fileCalc failure, $!";
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    next if $line =~ /^#+/;
    my ($expr, $rst) = split(/\s*=\s*/, $line);
    ok(`echo $expr | bc` == $rst, $expr);
}
close($fh);
#
#
#
#
#
