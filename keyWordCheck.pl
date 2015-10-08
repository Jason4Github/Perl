#!/usr/local/bin/perl
use File::Copy;
use File::Basename;


if ( $#ARGV < 1)
{
	print ("Usage: perl $0 keyWord path\n");
	exit 1;
}

$keyWord  = $ARGV[0];
$queryPath  = $ARGV[1];
$interval   = 30; #10 seconds
$queryCmd   = "find $queryPath -iname \"$keyWord\" ";

operation();

$i = 0;
exit $exit_value;

sub checkKeyWord {
    my $log = shift;
    my $child_pid = fork();
    if ( $child_pid == 0 ) {
        open (STDOUT, ">$log") or die "keyWord checker could not open $log for STDOUT.\n";
	$keyWord =~ m/(\w+)/i;
	my $re = $1; 
        while(1) {
            sleep $interval;
	    $i++;
	    my $dif = `$queryCmd`;
	    if ( $dif =~ m/$re/i ) {
    		print STDOUT "Find $keyWord!\n";
    		print STDOUT "file: $dif\n";
		`mail -s "find $keyWord in $queryPath" 'haisheng.yu\@oracle.com' < $log`;
		close STDOUT;	
		exit 1;
	    }
	    if ($i > 600) {
    		print STDOUT "no $keyWord find, within 5 hours\n";
		close STDOUT;   
                exit 1; 
	    } 
        }
	close STDOUT;	
        exit 1;
    } else {
        return $child_pid;
    }
}

sub operation {
	checkKeyWord("$queryPath/checker.log");
	$exit_value = 0;
}
