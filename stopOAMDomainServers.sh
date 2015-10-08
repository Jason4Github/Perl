#!/bin/bash


binFile="/scratch/OIM_OAM_WLS_R2PS2/mw5436/user_projects/domains/WLS_IDM/bin"


$binFile/stopWebLogic.sh
$binFile/stopManagedWebLogic.sh oam_server1 
$binFile/stopManagedWebLogic.sh oaam_admin_server1
$binFile/stopManagedWebLogic.sh oaam_server_server1

