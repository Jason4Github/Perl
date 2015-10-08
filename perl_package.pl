#! /usr/bin/perl

use strict;
use warnings;

sub findPackageTest {
    use File::Find;
    
    my $fileCnt = 0;
    find(sub{print "file: $File::Find::name \n"; $fileCnt++ if -f $_;}, '/scratch/haisyu/script_haisyu');
    print "file count: $fileCnt\n";
    print "=================DONE==================\n";

    no File::Find;
}

print "===============start================\n";
findPackageTest();
