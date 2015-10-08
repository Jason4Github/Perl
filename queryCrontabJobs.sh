#!/bin/bash


if [ $# -ne 2 ];then
	echo "useage: `basename $0` host_file_path your_cmds"
	exit
fi

fileName=$1
cmds=$2
logFile="/net/slc00bqn/scratch/allUsers/runningResults.log"



sshToHost() {
	local host=$1
	local user=$2
	local passwd=$3
	local runCmds=$4

	echo "$host  $user  $passwd  $runCmds"
	sleep 10s
	expect <<EOF
		set timeout -1
		spawn ssh $user@$host "$runCmds"
		expect {
			"*yes/no*" {send "yes\r"; exp_continue}
			"*assword*" {send "$passwd\r"; exp_continue}
			eof {return}
		}
EOF
}

export -f sshToHost

for i in `cat $fileName`
do
    if [[ $i =~ ((^[[:space:]]+$)|^\\#) ]];then
        continue
    fi
    arr=(${i//;/ })
    host="${arr[0]}"
    user="${arr[1]}"
    password="${arr[2]}"
    #echo "$host, $user, $password"

#    for cmd in $(echo $cmds | awk -F ";" '{for (i=1; i<=NF;i++){print $i }}')
#    do
#		echo $cmd
#        localCmds="$localCmds;$cmd 2>&1 >> $logFile"
#		echo $localCmds
#    done
    sshToHost "$host" "$user" "$password" "$cmds"

done
