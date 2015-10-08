#!/usr/bin/perl
use strict;
use warnings;


use IO::Socket;
#IO::Socket is a higher level abstraction
#Hides many of the ugly part we had to know in case of the socket() function.
## Provides an OOP interface.
##my $host = ¡¯127.0.0.1¡¯;
#my $host = 'slc03rmj.us.oracle.com';
#my $host = 'localhost';
my $host = "www.ifeng.com";
my $port = 80;
my $CRLF = "\015\012";
print "======debug======\n";
my $socket = IO::Socket::INET->new(
	PeerAddr => $host,
	PeerPort => $port,
	Proto => 'tcp') or die $!;
print "======debug======\n";
$socket->send("GET /$CRLF") or die $!;
print "======debug======\n";
my $SIZE = 10;
my $data = '';
print "======start getting======\n";
while ($socket->read($data, $SIZE, length $data) == $SIZE) {};
print $data;
#
