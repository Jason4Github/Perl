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

binFile="/scratch/OIM_OAM_WLS_R2PS2/mw5436/user_projects/domains/WLS_IDM/bin"

appendDate=`date +%y_%m_%d_%H:%M:%S`
wlsLog="oamDomain_admin_console_$appendDate.log"
nohup $binFile/startWebLogic.sh 2>&1 >$wlsLog &
check_RUNNING "$wlsLog"


oamLog="oamDomain_oam_console_$appendDate.log"
nohup $binFile/startManagedWebLogic.sh oam_server1 2>&1 >$oamLog &
check_RUNNING "$oamLog"

oaamAdminLog="oamDomain_oaamAdmin_console_$appendDate.log"
nohup $binFile/startManagedWebLogic.sh oaam_admin_server1 2>&1 >${oaamAdminLog} &
check_RUNNING "$oaamAdminLog"

oaamManagedLog="oamDomain_oaamManaged_console_$appendDate.log"
nohup $binFile/startManagedWebLogic.sh oaam_admin_server1 2>&1 >${oaamManagedLog} &
check_RUNNING "$oaamManagedLog"


