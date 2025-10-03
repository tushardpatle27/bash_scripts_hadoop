#!/bin/bash

curr_dir=$(pwd)
config_file_path=../conf/config.yaml

## ------------------------------------------------------ Get server type details ------------------------------------------------------

# echo "-------------------------------"
# echo "Fetching details .."
hadoop_cluster_type=$(cat "$config_file_path" | grep ^HADOOP_CLUSTER_TYPE | cut -d ":" -f 2)
hadoop_cluster_type_final=$(echo $hadoop_cluster_type | sed 's/[\%*,&();`{}]//g' | sed 's@[[:blank:]]@@')

## ------------------------------------------------------ Select hadoop scripts ------------------------------------------------------

echo "-------------------------------"
if [[ "$hadoop_cluster_type_final" == 'HA' ]]; then
	echo "Hadoop will be installed in $(tput setaf 2)'HA'$(tput sgr0) mode"
	sh hadoop_ha_setup.sh
elif [[ "$hadoop_cluster_type_final" == 'NON-HA' ]]; then
	echo "Hadoop will be installed in $(tput setaf 2)'NON-HA'$(tput sgr0) mode"
	sh hadoop_nonha_setup.sh
else
	echo "Please correct the given 'HADOOP_CLUSTER_TYPE' value $(tput setaf 1)'$hadoop_cluster_type'$(tput sgr0)"
	exit 1;
fi
