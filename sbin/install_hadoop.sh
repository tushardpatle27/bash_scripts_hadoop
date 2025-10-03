#!/bin/bash

source ~/.bashrc

# INSTALL_DIRECTORY will be udated by ../bin/hadoop_setup.sh
INSTALL_DIRECTORY=/home/ec2-user

set -e

cd $HOME
mkdir -p "$INSTALL_DIRECTORY/tdss"
if [[ ! -d "$INSTALL_DIRECTORY/tdss/hadoop" ]]; then
    echo "Installing Hadoop under $INSTALL_DIRECTORY/tdss"
    # untar hadoop
    tar -xf hadoop*.tar.gz
    # move
    tar_file=$(ls | grep hadoop*.tar.gz)
    tar_file_final=${tar_file//.tar.gz/}
    mv "$tar_file_final" "$INSTALL_DIRECTORY/tdss/hadoop"
    # clear
    rm hadoop*.tar.gz
else
    echo "Hadoop already installed"
    rm hadoop*.tar.gz
    exit;
fi

# clear bashrc
sed -i '/HADOOP/d' ~/.bashrc

# update bashrc
echo "" >> ~/.bashrc
echo "# Added by installer - HADOOP" >> ~/.bashrc
echo "" >> ~/.bashrc
#echo "export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")" >> ~/.bashrc
echo "export HADOOP_HOME=$INSTALL_DIRECTORY/tdss/hadoop" >> ~/.bashrc
echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> ~/.bashrc
echo "export HADOOP_LOG_DIR=\$HADOOP_HOME/logs" >> ~/.bashrc
echo "export HADOOP_MAPRED_DIR=\$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_COMMON_HOME=\$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_HDFS_HOME=\$HADOOP_HOME" >> ~/.bashrc
echo "export YARN_HOME=\$HADOOP_HOME" >> ~/.bashrc
echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native" >> ~/.bashrc
echo "export HADOOP_HOME_WARN_SUPPRESS=1" >> ~/.bashrc
echo "export YARN_HOME=\$HADOOP_HOME" >> ~/.bashrc
echo "export YARN_LOG_DIR=\$HADOOP_LOG_DIR" >> ~/.bashrc
echo "export YARN_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$HADOOP_HOME/lib/native:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.bashrc

#export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el7_9.x86_64/jre >> ~/.bashrc
#hbase


source ~/.bashrc
source ~/.bashrc

set +e
