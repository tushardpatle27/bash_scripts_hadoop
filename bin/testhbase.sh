#!/bin/bash
source=../conf/config.yaml
#HBASE_REGION_IP=$(cat "$source" | grep ^HBASE_REGION_IP | cut -d ":" -f 2)
HBASE_MASTER_IP=$(cat "$source" | grep ^HBASE_MASTER_IP | cut -d ":" -f 2)

#IFS="," read -ra server <<< "$HBASE_REGION_IP"
#for t in "${server[@]}"
#do
#echo $t 
#done


IFS="," read -ra servers <<< "$HBASE_MASTER_IP"
for t in "${servers[@]}"
do
echo $t
done
