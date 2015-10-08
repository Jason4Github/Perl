#!/bin/bash




expect -c '
set timeout -1
spawn ssh nowang@slc03nxi.us.oracle.com "/scratch/haisyu/runNXI.sh; uname -a; df -h"
expect {
"*yes/no*" {exp_send "yes\r"; exp_continue}
"*password*" {exp_send "welcome1\r"; exp_continue}
eof {return}
}
'
