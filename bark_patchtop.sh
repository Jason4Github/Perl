#!/bin/sh

today=`date +"%Y_%m_%d"`
patchtop="/scratch/tifan/Jason/patchtop_dummy_r2ps2/"
zipFile="/scratch/tifan/Jason/bark/patch_r2ps2_$today.tgz"
tar -cvzf $zipFile $patchtop
patchtop_r2ps3="/scratch/tifan/Jason/patchtop_r2ps3/"
zipFile_r2ps3="/scratch/tifan/Jason/bark/patch_r2ps3_$today.tgz"
tar -cvzf $zipFile_r2ps3 $patchtop_r2ps3
#scp -r $zipFile nowang@slc03nxi.us.oracle.com:/scratch/nowang/haisyu/patchtop/

scpAuto() {
    expect -c "
        spawn scp -r $zipFile $zipFile_r2ps3 $ldapfiletarg nowang@slc03nxi.us.oracle.com:/scratch/haisyu/patchtop/
        set timeout -1
        expect {
            \"*\(yes/no\)?\" { send \"yes\r\"; exp_continue }
            \"*password*\" { send \"welcome1\r\"; exp_continue }
             eof { return }
        }
    "
}


#  "*yes/no" { send "yes\r"; exp_continue }


ldapfile="/scratch/tifan/Jason/R1PS1_LDAP/r1ps1TopoAddUser.ldif"
ldapfiletarg=${ldapfile}_$today
cp -r $ldapfile $ldapfiletarg
[ $? -eq 0 ] && scpAuto && rm -rf $ldapfiletarg $zipFile $zipFile_r2ps3

#exec expect -f "/scratch/tifan/Jason/script/scpExcept.exp"
