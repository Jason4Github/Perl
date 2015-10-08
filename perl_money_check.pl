#!/bin/env perl
#
use strict;
use warnings;

sub verify_money {
	my $money = shift;

	return 1 if $money =~ /(^(?:\d{1,3},)?(?:\d{3},)*(?:\d{3})$)|(?:^\d{1,3}$)/;
	return 0;
}

sub create_money {
	my $range = shift;
	my $digital = [0..9];
	my $money = join("", map({$digital->[int(rand 10)]} 0..$range));

	use YAPE::Regex::Explain;	
	print "range: $range, digital: $money\n";
	my $re = qr{^(\d{1,3})((\d{3})+)$};
	#$money =~ s/^(\d{1,3})((\d{3})+)$/$1,$2/; #after replace, the pos of the string is 0. pos() will return undef
	$money =~ s/$re/$1,$2/g;
	print "first change: $money, \$1:[$1], \$2:[$2], \$3:[$3]\n";
	print YAPE::Regex::Explain->new($re)->explain;
	#$re = qr{(?<=\d{3})(\d{3})+};
	$re = qr{(?<=\d{3})(\d{3})};
	#$money =~ s/(?<=\d{3})(\d{3})/,$&/g; #$& or $1 all correct.
	$money =~ s/$re/,$1/g;
	#$money =~ s/(?<!\.\d)(?<=\d)(?=(?:\d{3})+$)/,/g;
	print "second change: $money, \$1:[$1], \$&:$&\n";
	print YAPE::Regex::Explain->new($re)->explain;
	my $pos = pos($money);
	print "second change: $money, pos: @{[ pos($money) ]} $pos\n" if defined $pos;

	print "got money [$money]\n";

	return $money;
}

sub re {
	my $line = "hello word, he is singing a song";

	my $s = "o**";
	$line =~ /\Q$s/;
	my $words = () = $line =~ /\w/g;
	print "[$line] has $words characters\n";
	
	print "get singing\n";
	print "\$&_\\w+?ing: [$&]\n" if $line =~ /\w+?ing\b/g;#singing

	my $pos = pos($line);
	#$line = "hello word, he is singing a song";
	pos($line) = 0;
	print "\$&_\\w+(?=ing\\b): [$&]\n" if $line =~ /\w+(?=ing\b)/;#sing
	
	#$line = "hello word, he is singing a song";
	pos($line) = 0;
	print "\$&_(?=s)\\w\\b: [$&]\n" if $line =~ /(?=s)\w+\b/; #s

	#$line = "hello word, he is singing a song";
	pos($line) = 0;
	print "\$&_(<=s)\\w\\b: [$&]\n" if $line =~ /(?<=s)\w+\b/;#inging 
}

sub main {

	re();
	my $num = 10;
=off
	print "please input your money number: \n";
	while (chomp($num=<>)) {

		if (verify_money($num)) { 
			print "[$num] is a good moneny number\n"; 
		}
		else {
			print "[$num] is a wrong moneny number\n"; 
		}
	}
=cut
	while ($num--) {	
		my $range = int(rand(20));
		my $money = create_money($range);
		if (verify_money($money)) {
			print "[$money] is a good moneny number\n"; 
		}
		else {
			print "[$money] is a wrong moneny number\n"; 
		}
	}	
}

main();
