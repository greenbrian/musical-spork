#!/bin/bash

if [ "$1" = "-w" ] && [ "$2" -gt "0" ] && [ "$3" = "-c" ] && [ "$4" -gt "0" ]; then
	FreeM=`free -m`
        memTotal_m=`echo "$FreeM" |grep Mem |awk '{print $2}'`
        memUsed_m=`echo "$FreeM" |grep Mem |awk '{print $3}'`
        memFree_m=`echo "$FreeM" |grep Mem |awk '{print $4}'`
        memBuffer_m=`echo "$FreeM" |grep Mem |awk '{print $6}'`
        memCache_m=`echo "$FreeM" |grep Mem |awk '{print $7}'`
        memUsedPrc=`echo $((($memUsed_m*100)/$memTotal_m))||cut -d. -f1`
        if [ "$memUsedPrc" -ge "$4" ]; then
                echo "Memory: CRITICAL Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!|TOTAL=$memTotal_m;;;; USED=$memUsed_m;;;; CACHE=$memCache_m;;;; BUFFER=$memBuffer_m;;;;"
                exit 2
        elif [ "$memUsedPrc" -ge "$2" ]; then
                echo "Memory: WARNING Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!|TOTAL=$memTotal_m;;;; USED=$memUsed_m;;;; CACHE=$memCache_m;;;; BUFFER=$memBuffer_m;;;;"
                exit 1
        else
                echo "Memory: OK Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used|TOTAL=$memTotal_m;;;; USED=$memUsed_m;;;; CACHE=$memCache_m;;;; BUFFER=$memBuffer_m;;;;"
                exit 0
        fi
else		# If inputs are not as expected, print help. 
	sName="`echo $0|awk -F '/' '{print $NF}'`"
        echo -e "\n\n\t\t### $sName Version 2.0###\n"
        echo -e "# Usage:\t$sName -w <warnlevel> -c <critlevel>"
        echo -e "\t\t= warnlevel and critlevel is percentage value without %\n"
	echo "# EXAMPLE:\t/usr/lib64/nagios/plugins/$sName -w 80 -c 90"
        echo -e "\nCopyright (C) 2012 Lukasz Gogolin (lukasz.gogolin@gmail.com), improved by Nestor 2015\n\n"
        exit
fi