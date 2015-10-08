#!/usr/bin/perl
#
use warnings;
use strict;


#ssh to host -> update host kernerl -> run cmds

my $hostFile;
my $masterHost;
my $slaveHost;
#cmd1, create /u01 /u02

#purge edg env
# unmount
#my $umountDir = '/usr/local/packages/aime/ias/run_as_root \"umount /u01/oracle/idmtop && umount /u01/oracle/idmlcm && umount /u01/oracle/lcmdir && umount /u01/oracle/config\"'
my $umountDirs = '/usr/local/packages/aime/ias/run_as_root \"umount /u01/oracle/idmtop /u01/oracle/idmlcm /u01/oracle/lcmdir /u01/oracle/config\"';

#remove dirs
my $rmDirs = '/usr/local/packages/aime/ias/run_as_root \"rm -rf /u01; rm -rf /u02; rm -rf /scratch/jason/work/*; rm -rf /scratch/jason/.ssh/authorized_keys\"';

#reboot host
my $rebootHost = '/usr/local/packages/aime/ias/run_as_root \"reboot\"';


paraCheck();

destroyEnvPrepareInHost();


sub paraCheck {
    if ( $#ARGV != 0 ) {
       print("\n====================================\n");
       print("useage: \n");
       print("$0 hostsFilePath \n");
       print("====================================\n");
       exit 1;
    }

    print "start running ... \n";
}


sub sshCmd {
    my $user = shift;
    my $host = shift;
    my $cmds = shift;

    chomp ($user = $user);
    chomp ($host = $host);

    return my $sshCmd = "expect -c '
set timeout -1
spawn ssh $user\@$host \"$cmds\"
expect {
\"*yes/no*\" {exp_send \"yes\r\"; exp_continue}
\"*password*\" {exp_send \"welcome1\r\"; exp_continue}
eof {return}
}
'"


}

sub destroyEnvPrepareInHost {
    foreach my $file (@ARGV) {
        chomp ($hostFile = $file);
        print("currnt host file: $hostFile\n");
        if ( open(my $FH, "<$hostFile") ) {
            while (<$FH>) {
                chomp (my $host = $_);
                $host =~ m/[\n\r\s]/ && next;
                if ( $host =~ m/master/i ) {
                    print "$host is a master host, which get from host file \"$hostFile\"\n";
                    chomp( $masterHost = substr($host, 0, index($host, ';')) );
                    my $cmdIn = "$rmDirs; $rebootHost";
                    $cmdIn =~ s/\n\r/\s/g;
                    my $cmd = sshCmd("jason", "$masterHost", $cmdIn);
                    my $result = `$cmd`;
                    print("result: $result\n"); 
                } else {
                    print "$host is a slave host, which get from host file \"$hostFile\"\n";
                    $slaveHost = $host;
                    my $cmdIn = "$umountDirs; $rmDirs; $rebootHost";
                    $cmdIn =~ s/\n\r/\s/g;
                    my $cmd = sshCmd("jason", "$slaveHost", "$cmdIn");
                    my $result = `$cmd`;  
                    print("result: $result\n"); 
                }

            }
            close $FH;
        } else {
            print("$hostFile can NOT be opened!, ERROR: $!\n");
        }
    }
}
