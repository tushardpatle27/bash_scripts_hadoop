#!/bin/bash

# untar saprk-jars.tar.gz
tar -xvf spark-jars.tar.gz
rm -r spark-jars.tar.gz

# push to HDFS
jars_dir=/tookitaki
set -e
hadoop fs -mkdir -p "$jars_dir"/tdss/spark
hadoop fs -put ~/spark/* "$jars_dir"/tdss/spark

rm -rf spark
set +e
