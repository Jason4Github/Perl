#!/bin/bash



#useage
if [ $# -ne 1 ]; then
	echo "useage: `basename $0` host_file_absolute_path"
	exit
fi

#log file
log="result.log"
sshKeyGen="$HOME/scripts/batch/sshKeyGen.sh"
#generate key
idfile="${HOME}/.ssh/id_rsa.pub"
if [ ! -f $idfile ]; then
	sh "$sshKeyGen"
fi

#ensure ssh-copy-id works
eval `ssh-agent`
ssh-add 2>&1 >> $log

fileName="$1"
#read from $1, get host/user/pwd
host=""
user=""
password=""

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
	expect -f sshCopyId.exp $host $user $password $idfile 2>&1 >> $log 
done



