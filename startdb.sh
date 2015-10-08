#!/bin/bash


export ORACLE_HOME=/scratch/PROV_OAM/db/product/11.2.0
export ORACLE_SID=orcl

$ORACLE_HOME/bin/lsnrctl start

if [[ $1 =~ config ]];then
echo "start to startup db and alter some para value"
$ORACLE_HOME/bin/sqlplus '/ as sysdba'<<EOF
alter system set java_pool_size='140M' scope=spfile;
alter system set shared_pool_size='200M' scope=spfile;
alter system set db_cache_size='160M' scope=spfile;
alter system set session_max_open_files=50 scope=spfile;
alter system set session_cached_cursors=500 scope=spfile;
alter system set processes=1000 scope=spfile;
alter system set open_cursors=1600 scope=spfile;
alter system set db_files=600 scope=spfile;
alter system set sga_max_size=4294967296 scope=spfile;
shutdown immediate
startup
EOF
else
$ORACLE_HOME/bin/sqlplus '/ as sysdba'<<EOF
startup
EOF
fi
#@/scratch/PROV_OAM/db/product/11.2.0/rdbms/admin/xaview.sql
