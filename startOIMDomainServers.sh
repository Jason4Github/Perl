#!/bin/bash


count=0

check_RUNNING() {
    log=$1
    while :
    do
	grepResult=`grep RUNNING $log`
	if [[ $grepResult =~ "RUNNING" ]];then
	    echo "Got RUNNING in log $log"
            echo 
	    break
	else
	    sleep 10s
	    let "count++"
	    [ $count -gt 50 ] && break
	fi
    done
}

binFile="/scratch/OIM_OAM_WLS_R2PS2/mw5436/user_projects/domains/WLS_IDM2/bin"


appendDate=`date +%y_%m_%d_%H:%M:%S`

oimAdminLog="oimDomain_admin_console_$appendDate.log"
soaLog="oimDomain_soa_console_$appendDate.log"
oimLog="oimDomain_oim_console_$appendDate.log"

nohup $binFile/startWebLogic.sh 2>&1 > $oimAdminLog &
check_RUNNING "$oimAdminLog"

nohup $binFile/startManagedWebLogic.sh soa_server1 2>&1 > $soaLog &
check_RUNNING "$soaLog"

nohup $binFile/startManagedWebLogic.sh oim_server1 2>&1 > $oimLog &
check_RUNNING "$oimLog"

