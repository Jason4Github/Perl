#! /bin/env perl
#
#
use strict;
use warnings;

sub node {
	my ($value, $next) = @_;

	my $self = {
		'value' => $value,
		'next'  => $next,
	};
	return $self;
}

sub printRing {
	my $head = shift;
	my $tail = $head;
	while($tail->{next} != $head) {
		print "value: $head->{value}\n";
		$tail = $tail->{next};
	}
}

sub josephuRing {
	my ($n, $m) = @_;

	#create ring
	my $head = node(1, undef);
	my $tail = $head;
	foreach my $i (2 .. $n) {
		$tail->{next} = node($i, undef);
		$tail = $tail->{next};
	}
	$tail->{next} = $head;

	#for debug
	#printRing($head);	
	#use Data::Dumper;
	#print Data::Dumper->Dump([$head], ["head"]);
	#no Data::Dumper;
	
	#remove the $m
	my $j;
	while($head->{next} != $head){
		for(my $j=1; $j<$m; $j++) {
			$tail = $head;
			$head = $head->{next};
		}
		$tail->{next} = $head->{next};
		print "remove the loser: $head->{value}\n";
		$head = $tail->{next};
	}
	
	print "the winner is $head->{value}\n";
}

josephuRing(10, 3);
