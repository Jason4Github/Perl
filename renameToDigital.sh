#!/bin/bash

self=`basename $0`
[ $# -lt 1 ] && echo "useage: $self folderPath" && exit

path=$1
i=1

for fl in `find $path -type f`
do
   [[ $fl =~ $self ]] && continue
    mv $fl new$i.wav
    let "i=$i+1"
done
