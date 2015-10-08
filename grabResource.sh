#!/bin/bash



#grab *.tgz in slc07gab.us.oracle.com
gab="slc07gab.us.oracle.com"
nui="slc03nui.us.oracle.com"
var="temp"
cmd='cd /scratch; for tgzFile in \`find . -maxdepth 1 -name \"*.tgz\" \`; do src=\${tgzFile#*/};  expect -f /net/slc00bqn/scratch/jason_bark_do_NOT_remove/scp.exp  \$src gab ; done'
cmd_nui='cd /scratch/haisyu; for tgzFile in \`find . -maxdepth 1 -name \"*.tgz\" \`; do src=\${tgzFile#*/};  expect -f /net/slc00bqn/scratch/jason_bark_do_NOT_remove/scp.exp  \$src gab ; done'


<<off
expect <<EOF
set timeout -1

spawn ssh jason@$gab "$cmd"

expect {
	"*yes/no*" {exp_send "yes\r"; exp_continue}
	"*password*" {exp_send "welcome1\r"; exp_continue}
	eof {return}
}
EOF
off

expect <<EOF
set timeout -1

spawn ssh jason@$nui "$cmd_nui"

expect {
    "*yes/no*" {exp_send "yes\r"; exp_continue}
    "*password*" {exp_send "welcome1\r"; exp_continue}
    eof {return}
}         
EOF 
