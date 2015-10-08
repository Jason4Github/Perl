#!/usr/bin/perl
#
use strict;
use warnings;

use Expect;

my $ssh = "ssh wazheng@slc03rmj.us.oracle.com";
my $e = Expect->new;
$e->raw_pty(1);
$e->spwan($ssh) or die "FAIL: $ssh  $!";
$e->expect(1, "yes");
$e->send("yes\n");
$e->expect("assword") or die "not GOT expect password";
$e->send("welcome1");
$e->send("echo hello");
$e->expect(1, "hello"); or die "not GOt hello";

pirnt "SUCCESS\n";
