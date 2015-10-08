#	NAME
#		TxLib.pm - My frequently used functions.
#	DESCRIPTION
#		This class provides all my frequently used functions.
#
#	VERSION		(MM/DD/YY)
#	0.1			 11/25/13 - Creation. Add input parameter checking subroutine.
package mylib;
use POSIX qw(tzset);

# Read the file contents into an array with each element storing a single line.
# The ending \n is not chomped.
sub read_file {
    my $file = shift;
    open my $in, "<", $file or die "Cannot open file \"$file\": $!";
    my @res = <$in>;
    close $in or die "$in: $!";
    return @res;
}

# Remove leading and trailing white spaces.
sub remove_whitespaces {
	my $res = shift;
	$res =~ s/^\s*(.*?)\s*$/$1/;
	return $res;
}

# Get key and val from lines with pattern "KEY=VALUE"
# If multiple "=" exist, cut from the first occurrence.
sub get_kv {
    my $line = shift;
	chomp $line;
    my @tmp = split("=", $line, 2);
    my $key = remove_whitespaces($tmp[0]);
    my $val = "";
	$val = remove_whitespaces($tmp[1]);
    my %res = (
        'key'=>$key,
        'val'=>$val,
    );
    return %res;
}

# Read configuration files.
# Ignore white lines and line that started with "#" (comments)
sub load_conf(){
	my $conf_file = shift;
	my @contents = read_file($conf_file);
	my %hash = ();
	my %kv = ();
	foreach my $line (@contents){
		if ( $line =~ m/^#/ ) {
			next;
		}
		chomp $line;
		$line = remove_whitespaces($line);
		if ( $line eq "" ) {
    		next;
		}
		%kv = get_kv($line);
		$hash{$kv{'key'}}=$kv{'val'};
	}
	return %hash;
}

# Open a file output handler and return.
sub write_to_file {
    my $output_file = shift;
    open(my $out, ">", $output_file) or die "Can't open $output_file: $!";
    return $out;
}

# Close an opend file. Used after file written is done.
sub close_file {
    my $out = shift;
    close $out or die "$out: $!";
}

# Set timezone to China.
sub set_timezone {
    my $tz = shift;
    $ENV{TZ} = $tz;
    tzset();
}

sub getHostIp {
    my $host = shift;
 
    my $cmd = "ping -c 2 $host | grep -i 'data' | awk '{print \$3}' | tr -d \\(\\)";
    return my $ip = `$cmd`;

}


sub hostip {
    use Socket;
    my $hostname = `hostname`;
    chomp $hostname;
    my $address = inet_ntoa(inet_aton($hostname));
    $address = remove_whitespaces($address);

    return $address;
}


#$remoteRun = sshCmd("Host", "user", "pwd", "cmdIn");
sub sshCmd {
    my $host = shift;
    my $user = shift;
    my $pwd = shift;
    my $cmds = shift;

    chomp ($host);
    chomp ($user);
    chomp ($pwd);

    return my $sshCmd = "expect -c '
set timeout -1
spawn ssh $user\@$host \"$cmds\"
expect {
\"*yes/no*\" {exp_send \"yes\r\"; exp_continue}
\"*password*\" {exp_send \"$pwd\r\"; exp_continue}
eof {return}
}
'"
}


#sort hash table
sub sortHash {
    my %hash = shift;
    my @buf =();

    foreach my $key (sort {$hash{$b}<=>$hash{$a} or $a cmp $b} keys %hash) {
		my $line = sprintf("%-15s=%-15s\n", $key, $hash{$key});
		push(@buf, $line);
    }

    return @buf;    

}

sub createFileBySize {
	my ($file, $size) = @_;

	my $fh = write_to_file($file);
	my $file_size = 0;
	my @strArray = (0..9, 'a'..'z', 'A'..'Z');
	my $strArrayLen = @strArray;

	while(1) {
		my $strLen = int(rand(10)) + 1;
		my $string = join("", map({$strArray[int(rand($strArrayLen))]} 1..$strLen));		
		print $fh "$string\n";
		$file_size += $strLen + 1;
		last if $file_size >= $size;
	}

	close_file($fh);
}

sub getLatestLabelByAde {
    my $series = shift;

    my @labels = `/usr/dev_infra/platform/bin/ade showlabels -series $series`;
    my $latest = $labels[-1];
    chomp $latest;
    
    return $latest;
}



return 1;
