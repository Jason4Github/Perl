#!/usr/bin/perl
#
#


sub getJobs {	
	#read nohup.out
	my $fn = "nohup.out";
    if ( $#ARGV >= 0 ) {
        $fn = $ARGV[0]
    }

	print "get hosts from file: $fn. waiting......\n";
	my @jobs = ();
	open ( my $fh, "<", "$fn" ) or die "open $fn failure! $!\n";
	while ( my $line = <$fh> ) {
		if ( $line =~ m/\((farm.+?)\)/g) {
			push(@jobs, $1);
		}

	}

	close($fh);
	return @jobs;

}

sub getHostFromJob {
	my @jobs = getJobs();
	#my @jobs = ("farm showjobs -d -j 15205653", "farm showjobs -d -j 15212281", "farm showjobs -d -j 15205653");
	my @hosts = ();
	foreach my $job (@jobs) {
		my $result = `$job`;
		if ( $result =~ m/started=1,\s*done=0/g and $result =~ m/\/aime1_(\w+)\//g) {
			push(@hosts, "$1.us.oracle.com");
		}	

	}
	return @hosts;

}

sub generateHostFile {
	my @hosts = getHostFromJob();
	my $fn = "hostfile.log";
    if ( $#ARGV >= 1 ) {
        $fn = $ARGV[1]
    }

	my $date = `date +%Y-%m-%d:%H:%M:%S`;
	`mv $fn $fn.$date`;
	open( my $fh, ">", "$fn") or die "create host file $fn failure! $!\n";	
	foreach $host (@hosts) {
		print $fh "$host\n"
	}
	close($fh);

	print "please find host name from file: $fn\n";
}

generateHostFile();


