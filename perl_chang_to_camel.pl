#! /usr/bin/perl -w
#
#
#
#
use strict;

sub useage {
	print <<EOF
		This script used to change named rule to CamelCase.

		useage: $0 yourFileFullPath  e.g. $0 /home/scrip_file
EOF

}

sub changeToCamelCase {
	my $file = shift; 
    
	my $newFile = "$file.camelCase"; #camelCase naming file
	open(my $fhNew, ">$newFile");
	
	open(my $fh, "+<$file"); #read what need to be changed file
	my @lines = <$fh>;
	foreach my $line(@lines) {
		#my @words = split(/(?=_)/, $line); #not work
		my @words = split(/_(?!;)/, $line);
		my $newLine =join("",  map(ucfirst, @words));
		$newLine =~ s/^([USM])/\l$1/;
		print $fhNew "$newLine";
	}
	close($fh);


	close($fhNew);
	chmod(0744, $newFile);	

}

sub main {
	my $file = $ARGV[0];
	unless (defined $file) {
		useage();
		return;
	}

	changeToCamelCase($file);	

}

main();
1
