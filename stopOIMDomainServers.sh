#!/bin/bash


binFile="/scratch/OIM_OAM_WLS_R2PS2/mw5436/user_projects/domains/WLS_IDM2/bin"

nohup $binFile/stopWebLogic.sh 2>&1 >>oimDomain_admin_console.log &

nohup $binFile/stopManagedWebLogic.sh soa_server1 2>&1 >>oimDomain_soa_console.log &

nohup $binFile/stopManagedWebLogic.sh oim_server1 2>&1 >>oimDomain_oim_console.log &

