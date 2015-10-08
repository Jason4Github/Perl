#!/bin/sh





dt=`date`
java=`ps -ef | grep -i java `
if [[ $java =~ "oim" ]]; then
	echo "$dt, got oim in process" >> /scratch/haisyu/ssh.test.log
else
	echo "$dt, NOT got oim in process" >> /scratch/haisyu/ssh.test.log
fi
