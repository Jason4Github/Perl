#!/bin/bash


if [ $# -ne 5 ];then
	echo "useage: `basename $0` sourceFilePath user pwd host tagPath"
	exit
fi

sourceFilePath=$1
user=$2
passwd=$3
host=$4
tagPaht=$5


expect -f scp_general.exp $sourceFilePath $user $passwd $host $tagPath
