#!/usr/bin/perl
#
#
#
#
#
#

BEGIN {
    use File::Basename;
    use Cwd;

    $orignalDir = getcwd();

    $scriptDir = dirname($0);
    chdir($scriptDir);
    $scriptDir =  getcwd();

    $plibDir = "$scriptDir/plib";
    chdir($plibDir);
    $plibDir = getcwd();

    # add $plibDir into INC
    unshift(@INC,"$plibDir");
    chdir($orignalDir);

}

use mylib;




print "====================\n";


sub get_base {
    my $sh = shift;
    $sh =~ m/\/\w+?\/\w+?(?=\/script.*)/i;
    my $base = $&;
	print "base: $base\n";

	$base = "$base abc";
	print "base: $base\n";

	print "arg: $sh\n";
}

get_base("/u01/idmr2ps3_prov/scripts/startdb.sh");

exit ;

my $tmpi = "identity\n";
my $tmpg = "governance\n";
my $tmpn = "iden,gov";

if ($tmpi =~ /identity|governance/i ) {
	print "got $tempi\n";
} 

if ($tmpg =~ /identity|governance/i ) {
    print "got $tempi\n";
}
if ($tmpn =~ /identity|governance/i ) {
    print "got $tempn\n";
} else {
	print "not got, $tempn\n";
}

exit 1;


my $tmpa = " aADF.af_sdc=fasf/dfasdf/dfas/ \n";
print "===$tmpa===\n";
chomp $tmpa;
$tmpa =~ s/^\s*(.*?)\s*$/$1/;
print "===$tmpa===\n";



my %h = ("  oracle_home" => "/abc/abc  \n", "home" => "/home");
foreach my $key (keys %h) {
	print "$key: $h{$key}\n";
	my $tmp = "$key";
    $tmp =~ s/\s*(.*?)\s*$/$1/g;
	print "$tmp\n";
	$tmp = "$h{$key}";
	chomp $tmp;
	$tmp =~ s/\s*(.*?)\s*$/$1/g;
	print "$tmp\n";

}

exit 1;


my $tmp =  "/scratch/u01";
$tmp =~ s/\//\\\//g;
my $cmd = "/usr/local/packages/aime/asm/run_as_root \"sed -i '/$tmp\\s\*\\*(rw,sync,no_root_squash)/d' /etc/exports\"";
print "===cmd: $cmd\n";
    my $clean = readpipe("$cmd");
    print "remove $tmp in /etc/exports done!\n";
    my $cmd = "cat /etc/exports";
    my $show = readpipe("$cmd");
    print "cat /etc/exports\n$show\n";

exit 1;


    my $cmd = "/usr/local/packages/aime/asm/run_as_root \"sed -i '/idmprov.us.oracle.com/d' /etc/hosts\"";
    print "===cmd: $cmd\n";
    my $clean = readpipe("$cmd");
    print "remove *idmprov.us.oracle.com in /etc/hosts done!\n";
    my $cmd = "cat /etc/hosts";
    my $show = readpipe("$cmd");
    print "cat /etc/host\n$show\n";


sub getCurrentUser {
    my $uncmd = "id -un";
    my $un = `$uncmd`;
    chomp $un;

    return $un;
}

sub getPwd {
    my $un = getCurrentUser();
    my $pwd;

    if ( $un eq "aime" ) {
        $pwd = "2cool";
    } elsif ( $un eq "aime1" ) {
        $pwd = "coolkid1";
    } else {
        $pwd = "$ImportParamTable{HOST_PWD}";
    }

    return $pwd;
}

print "current user/pwd: ".getCurrentUser()."/".getPwd()."\n";

print "$0\n";
print "$#ARGV\n";
print "ARGV[0]: $ARGV[0]\n";
my $len1 = length(@ARGV);
print "len: $len1\n";

exit;

my $an1 = "/u02/local/oracle/config";
my $local = "";
print "$local\n";
my $leg=length($local);
print "len: $leg\n";
$local = $1 if $an1  =~ /(\/\w+?)\//; 
print "$local\n";


exit 1;

system("echo done >> test.log; echo done >> test.log");

sub test1{
		$log = "test.log";
        my $fh = "";
        if (open($fh, "<", "$log")) {
            while (my $line=<$fh>) {
                if ( $line =~ m/completed\s+successfully/g ) {
                    print("OTD install succeeded\n");
                    close($fh);
                    return 0;
                }
            }
            close($fh);
        }
}

test1();

exit 1;
   
my $r = system("ls -l 2>&1 > test.log");
print " $r\n";
$r = `cat test.log`;
print " $r\n";

exit 1; 
my $prov_run = "/scratch/haisyu/scripts/tmp.txt";
my $str = "startup, verify";
 
if ( open(my $fh, "<$prov_run") ) {

	if ( ! open($prov, ">$prov_run.ok") ) {
		print "open failure, $!\n";
	}
	while ( my $line = <$fh> ) {
		print $prov "$line";
	}
	close $fh;
	close $prov;
}

my $line = 'hello well world';
if ( $line =~ m/hello\ well/g) {
	print("match hello\ well\n");

}


exit 1;
my $str = "123.zip";
my $str1 = "123.zip;";
my $str2 = "123.zip;dafd.zip";
my $r = index($str, ";");
print "r: $r\n";
my $r = index($str1, ";");
print "r: $r\n";
my $r = index($str2, ";");
print "r: $r\n";



my @arr = ();
if ( $str =~ m/([;:])/ ) {
        print "$str, got ;:|,\n";
}
if ( $str1 =~ m/([;:|,])/ ) {
	print "\$1: $1\n";
        @arr =  split(/$1+/, $str1);
	my $s = @arr;
	print "array size: $s\n@arr\n";
}
if ( $str2 =~ m/([|;:,])/ ) {
	print "\$1: $1\n";
        @arr =  split(/$1+/, $str2);
	my $s = @arr;
	print "array size: $s\n@arr\n";
        foreach my $patch (@arr) {
            print "patch: $patch\n";
        }

}

sub test($) {
	my $tmp =shift;
	print "param: $tmp\n";
}

test("hehdhhdd");
#test("hehdhhdd", "2"); #error, compile error since para numbers incorrect
exit 1;
print "@INC\n";

my $str = mylib::getHostIp("slc03rfg.us.oracle.com");
print "$str\n";

$str = dirname("/scratch/testDir/afc");
print "$str\n";

$str = mylib::hostip();
print "$str\n";

my $str ="  	dfdfad    ";
$str = mylib::remove_whitespaces($str);
print "$str\n";

exit;

my $str = "IDM_11.1.2.3.0_GENERIC_150607.0089";
my $str1 = " IDM_11.1.2.3.0_GENERIC_150607.0089 ";
my $str2 = "IDM_11.1.2.3.0_GENERIC_150607.0089";
my $str3 = "warning:sdff sdf";
$r = index($str, $str1);
print "r: $r\n";
$r = index($str1, $str);
print "r: $r\n";
$r = index($str2, $str);
print "r: $r\n";
$str3 !~ m/IDM_11\.1\.2\.3\.0_GENERIC_\d+?\.\d+/ && print "$str3 not match\n";

exit 1;

my $dir = getcwd();
print "cur dir: $dir\n";
my $cmd = "pwd; cd /scratch; pwd";
my $r = `$cmd`;
print "$r\n";
my $dir = getcwd();
print "cur dir: $dir\n";


my $str = "adsfadf sdfas f No such file or directory";
if ( -1 != index(lc($str), "no such file or directory")) {
	print "got, No such file or directory\n";
}

exit 1;


$ENV{abc}="tmp";
$ENV{abc_jason}="tmp2";
my $r = `/bin/bash -c -l env | grep abc; ./split.sh`;
print "$r\n";

exit 1;

$a1 = "dba";
$a2="dba ";
$a3="s1 dba cba";

@m1 = split(/\s+/, $a1);
print "got:$m1[0]\n";
@m2 = split(/\s+/, $a2);
print "got:$m2[0]\n";
@m3 = split(/\s+/, $a3);
print "got:$m3[0]\n";



exit 1;

my $str = "    a a a a s s d e e d sfsadfasdf    ";
my $ha = {};
$str =~ s/\s+/ /g;
chomp $str;
print "$str\n";
if ( $str =~ m/^\s+/) {
	$str = substr($str, 1);
	print "$str\n";
}
my @arr = split(/\s+/, $str);

foreach my $tmp (@arr) {

	$ha->{$tmp}++;
}

foreach my $tmp (sort{$ha->{$b} <=> $ha->{$a} or $a cmp $b} keys %$ha) {
	printf("%s: %-4d\n", $tmp, $ha->{$tmp});
}
exit 1;


#
#
#
#
my %directory;
sub data_for_path {
	my $path = shift;
	#return undef if -f $path or -l $path;
	return $path if -f $path or -l $path;
	if (-d $path) {
		opendir PATH, $path;
		my @names = readdir PATH;
		close PATH;
		for my $name (@names) {
			next if grep(/^\.\.?$/, $name);
			#next if $name eq '.' or $name eq '..'; #correct
			#			#next if $name eq '.' or eq '..'; #wrong
			$directory{$name} = data_for_path("$path/$name");
		}	
		return \%directory;
	}
	return undef;
}
my $dir = data_for_path $ARGV[0];

foreach $key (keys %$dir) {
	print "$key -> $dir->{$key}\n";
}

exit 1;
my $ha = {};
my $str="f f adfa f asd fs df  fds adfasdf";
my @s=split(/\s+/, $str);
print $s[0];
foreach my $tmp (@s) {
	$ha->{$tmp}++;
}

foreach my $key (sort{$ha->{$b}<=>$ha->{$a}} keys %$ha ) {
	print "$key -> $ha->{$key}\n";
}
exit 1;

my $test1 = "*.dif";
$test1 =~ m/(\w+)/i;
my $test2 = $1;
print "$test2\n";
my $i=1;
$i++;
print "$i\n";
my $keyWord = $ARGV[0];
my $queryPath = $ARGV[1];
my $log = "$queryPath/checknew.log";
`find $queryPath -iname $keyWord > $log`;
my $test3 = `mail -s "find $keyWord in $queryPath" 'haisheng.yu\@oracle.com' < $log`;
print "$test3\n";
exit 1;

print "$#ARGV\n";
my $len = length(@ARGV);
print "len: $len\n";

my $host=`hostname`;
print "testing\n";
my $cmd="/usr/local/packages/aime/ias/run_as_root 'echo cmd2 ; echo semicolone && echo and && echo $host:done; echo append'";
my $cmd2="/usr/local/packages/aime/ias/run_as_root 'echo cmd2\;echo semicolone&&echo and'  && \
/usr/local/packages/aime/ias/run_as_root 'echo haha'; echo ';'";

my $createDirs = "/usr/local/packages/aime/ias/run_as_root 'mkdir -p /u02/local/oracle/config && chown -R haisyu:dba /u02 && chown -R haisyu:dba /u02; mkdir -p /u01/oracle && chown -R haisyu:dba /u01' && mkdir /u01/oracle/idmtop && mkdir /u01/oracle/idmlcm && mkdir /u01/oracle/lcmdir && mkdir /u01/oracle/config";

my $res = `$cmd`;
my $res2 = `$cmd2`;
my $res3 = `$createDirs`;
#my $res2 = system("bash -c '$cmd'");
print "$res\n";
print "$res2\n";
print "$res3\n";

my $var="";
my $var2 = "$var.append";

$var = "new";
print "$var2\n";
$var2 = "$var.append";
print "$var2\n";

sub getHostIp {
    my $host = shift;
    #my $pingcmd = "ping -c 2 $host";
    #my $pipecmd = "| grep -i 'data' | awk '{print \$3}' | tr -d \\(\\)";
    #my $cmd = "$pingcmd.$pipecmd";
    
    my $cmd = "ping -c 2 $host | grep -i 'data' | awk '{print \$3}' | tr -d \\(\\)";
    return my $ip = `$cmd`;

}
my $ip = getHostIp "slc03nui.us.oracle.com";
print "$ip\n";

print(__FILE__, "\n");
