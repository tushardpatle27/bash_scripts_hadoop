#!/bin/bash
#Tesing sshpass
#source ../conf/config.yaml > /dev/null 2$>1

#Testing JAva
which java > /dev/null 2&>1
test2=$?
if [ $? -eq 0 ]; then
    echo "JAVA INSTALLED OK" 
else
    echo "JAVA NOT-INSTALLED FAILED" 
fi

#Testing OS
os="$(cat /etc/os-release | grep ^ID= | cut -d "=" -f 2 | tr -d '"')"
if [[ ("$os" -eq "rhel") || ("$os" -eq "centos") ]]; then
        echo "'$os' - INSTALLED OK" 
        
else
        echo "'$os' - Not Supported" 
        
fi

#Testing Ram
mem_kb="$(cat /proc/meminfo | grep MemTotal | cut -d ':' -f 2 | tr -d ' ' | cut -d 'k' -f 1)"
mem=$(expr $mem_kb / 1024)
if [[ $mem -ge 8192 ]]; then
        echo "MEMORY  '$mem MB' - OK" 
       
else
        echo "MEMORY  '$mem MB' - Not Supported"
        
fi


