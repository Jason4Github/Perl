#!/bin/bash



function sshHost() {
host=$1
cmd=$2
expect <<EOF
set timeout -1
spawn ssh jason@$host "$cmd"
expect {
"*yes/no*" {exp_send "yes\r"; exp_continue}
"*password*" {exp_send "welcome1\r"; exp_continue}
eof {return}
}
EOF

}


cmd0="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target preverify"
cmd1="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target install"
cmd2="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target preconfigure"
cmd3="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target configure"
cmd4="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target configure-secondary"
cmd5="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target postconfigure"
cmd6="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target startup"
cmd7="/u01/oracle/idmlcm/provisioning/bin/runIAMDeployment.sh -responseFile /scratch/jason/work/oracle/work/GENERATE_RSP_FILE/generic_provisioning_4node_oimha.rsp -target validate"

host1="slc03nst.us.oracle.com"
host2="slc03nsp.us.oracle.com"
host3="slc05mgr.us.oracle.com"

$cmd0 &&
sshHost "$host1" "$cmd0" &&
sshHost "$host2" "$cmd0" &&
sshHost "$host3" "$cmd0" &&

$cmd1 &&
sshHost "$host1" "$cmd1" &&
sshHost "$host2" "$cmd1" &&
sshHost "$host3" "$cmd1" &&


$cmd2 &&
sshHost "$host1" "$cmd2" &&
sshHost "$host2" "$cmd2" &&
sshHost "$host3" "$cmd2" &&

$cmd3 &&
sshHost "$host1" "$cmd3" &&
sshHost "$host2" "$cmd3" &&
sshHost "$host3" "$cmd3" &&


$cmd4 &&
sshHost "$host1" "$cmd4" &&
sshHost "$host2" "$cmd4" &&
sshHost "$host3" "$cmd4" &&


$cmd5 &&
sshHost "$host1" "$cmd5" &&
sshHost "$host2" "$cmd5" &&
sshHost "$host3" "$cmd5" &&


$cmd6 &&
sshHost "$host1" "$cmd6" &&
sshHost "$host2" "$cmd6" &&
sshHost "$host3" "$cmd6" &&


$cmd7 &&
sshHost "$host1" "$cmd7" &&
sshHost "$host2" "$cmd7" &&
sshHost "$host3" "$cmd7"


