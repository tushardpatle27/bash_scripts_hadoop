#!/bin/bash

source ../conf/config.yaml

conn_web(){

        if [[ "$TOMCAT_AUTH_MECH" == "KEY" ]];then
                ssh -i "$TOMCAT_SERVER_KEY_LOCATION"  "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$TOMCAT_SERVER_PASSWORD" ssh "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH" == "NIL" ]]; then
                ssh "$TOMCAT_SERVER_USERNAME"@"$t" $*
        else
                echo "unexpected token type"; exit;
        fi
}

IFS="," read -ra servers <<< "$ES_SERVERS_IP"
for t in "${servers[@]}"
do

conn_web "$INSTALL_DIRECTORY"/tdss/tomcat/bin/shutdown.sh
conn_web kill -9 $(ps -ef | grep Elasticsearch | head -1 |awk '{print $2}') > /dev/null

done
