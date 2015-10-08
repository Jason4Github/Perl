#!/usr/bin/perl
#

use strict;
use warnings;
use Net::SSH::Perl;

my $host = "slc03rfg.us.oracle.com";
my $user = "wazheng";
my $pwd  = "welcome1";
my $cmd  = "cat /etc/hosts; free -m; df-h; uptime; date; who";

my $ssh = Net::SSH::Perl->new($host, debug => 1);
print "done\n";

$ssh->login($user, $pwd);
my ($out, $err, $exit) = $ssh->cmd($cmd);
print "out:   $out\n";
print "error: $err\n";
print "exit:  $exit\n";
