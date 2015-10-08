#!/usr/bin/perl
use strict;
use warnings;

use Net::SSH qw(sshopen2);
use IO::File;

my $output = IO::File->new;
my $input = IO::File->new;
my $host = "slc03rfg.us.oracle.com";
my $user= "wazheng";

sshopen2("$user\@$host", $output, $input) or die $!;
print $input "cat /etc/hosts\n";
print $input "echo DONE\n";
print $input "who\n";
print $input "echo DONE\n";
print $input "date\n";
print $input "echo DONE\n";
print $input "free -m\n";
print $input "echo DONE\n";
print $input "df -h\n";
print $input "exit\n";

my @out = <$output>;
my $c=0;
my @section;

while (my $line = shift @out) {
    if ($line =~ /^DONE$/) {
        $c++;
        next;
    }
    push @{$section[$c]}, $line;
}

foreach my $sect (@section) {
    print @$sect;
    print "--------------------\n";
}
