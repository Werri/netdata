#!/bin/bash
if [ $# -gt 1 ]; then
   SDB=$1
   SDC=$2
   VAR=$(($(blockdev --getsize64 ${SDC}) / (1024*1024)-1024))
   echo -e "select ${SDB}\nresizepart\n1\n${VAR}MB\n" | parted
fi
