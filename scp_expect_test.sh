#!/bin/bash


expect <<EOF
set timeout -1

spawn scp /scratch/haisyu/tlr.properties nowang@slc03nxi.us.oracle.com:/scratch/haisyu
expect {
	"*yes/no*" {exp_send "yes\r"; exp_continue}
	"*password*" {exp_send "welcome1\r"; exp_continue}
	eof {return}
}


EOF
