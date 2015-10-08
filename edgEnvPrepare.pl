#!/usr/bin/perl
#
use warnings;
use strict;


#ssh to host -> update host kernerl -> run cmds

my $hostFile;
my $masterHost;
my $slaveHost;
my $masterHostIp;
#cmd1, create /u01 /u02
my $createDirs = '/usr/local/packages/aime/ias/run_as_root \"mkdir -p /u02/local/oracle/config && chown -R jason:dba /u02 && chown -R jason:dba /u02; mkdir -p /u01/oracle && chown -R jason:dba /u01\" && mkdir /u01/oracle/idmtop && mkdir /u01/oracle/idmlcm && mkdir /u01/oracle/lcmdir && mkdir /u01/oracle/config';

#
my $addU01Property = '/usr/local/packages/aime/ias/run_as_root \"echo /u01 *\\\(rw,sync,no_root_squash\\\)>>/etc/exports\"';
my $restartNfs = '/usr/local/packages/aime/ias/run_as_root \"/sbin/service nfs restart; /usr/sbin/exportfs -a; /usr/sbin/exportfs -v\"';



paraCheck();

startEnvPrepareInHost();


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


sub mountDirs {
    return my $mountDires = '/usr/local/packages/aime/ias/run_as_root \"/bin/mount -t nfs '."$masterHost".':/u01/oracle/idmtop /u01/oracle/idmtop && /bin/mount -t nfs '."$masterHost".':/u01/oracle/idmlcm /u01/oracle/idmlcm && /bin/mount -t nfs '."$masterHost".':/u01/oracle/lcmdir /u01/oracle/lcmdir && /bin/mount -t nfs '."$masterHost".':/u01/oracle/config /u01/oracle/config\" ' ;
}

sub hostsUpdate {
    return my $hostsUpdate = '/usr/local/packages/aime/ias/run_as_root \"echo '."$masterHostIp".'    sso-cdc-idmprov.us.oracle.com >> /etc/hosts && echo '."$masterHostIp".'    oamadm-cdc-idmprov.us.oracle.com >> /etc/hosts && echo '."$masterHostIp".'    idm-cdc-idmprov.us.oracle.com >> /etc/hosts && echo '."$masterHostIp".'    oimadm-cdc-idmprov.us.oracle.com >> /etc/hosts && echo '."$masterHostIp".'    oimsso-cdc-idmprov.us.oracle.com >> /etc/hosts\"';
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

sub getHostIp {
    my $host = shift;

    my $cmd = "ping -c 2 $host | grep -i 'data' | awk '{print \$3}' | tr -d \\(\\)";
    return my $ip = `$cmd`;

}

sub startEnvPrepareInHost {
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
                    chomp( $masterHostIp = getHostIp($masterHost) ); 
                    my $hostsUpdate = hostsUpdate();
                    my $cmdIn = "$createDirs; $addU01Property; $restartNfs; $hostsUpdate";
                    $cmdIn =~ s/\n\r/\s/g;
                    my $cmd = sshCmd("jason", "$masterHost", $cmdIn);
                    my $result = `$cmd`;
                    print("result: $result\n"); 
                } else {
                    print "$host is a slave host, which get from host file \"$hostFile\"\n";
                    $slaveHost = $host;
                    chomp( my $mountDirs = mountDirs() );
                    chomp( my $hostsUpdate = hostsUpdate() );
                    my $cmdIn = "$createDirs; $mountDirs; $hostsUpdate";
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
