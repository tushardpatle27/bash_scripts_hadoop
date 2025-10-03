#!/bin/bash

source ~/.bashrc

# INSTALL_DIRECTORY and MY_ID will be udated by ../bin/zookeeper_setup.sh
INSTALL_DIRECTORY=/home/ec2-user
MY_ID=3

set -e
## Install Zookeeper
cd $HOME
mkdir -p "$INSTALL_DIRECTORY/tdss"
if [[ ! -d "$INSTALL_DIRECTORY/tdss/zookeeper" ]]; then
	echo "Installing Zookeeper under $INSTALL_DIRECTORY/tdss"
	# untar Zookeeper
	tar -xf apache-zookeeper-*.tar.gz
	# move
	tar_file=$(ls | grep apache-zookeeper*.tar.gz)
    tar_file_final=${tar_file//.tar.gz/}
	
	mv "$tar_file_final" "$INSTALL_DIRECTORY/tdss/zookeeper"
	mv zoo.cfg "$INSTALL_DIRECTORY/tdss/zookeeper/conf/"
	rm apache-zookeeper*.tar.gz

else
    echo "Zookeeper already installed" 
    
    # Clear files (already placed by ../bin/zookeeper_setup.sh)
	echo "Removing unecessary files"
	rm apache-zookeeper*.tar.gz
	rm zoo.cfg
    exit;
fi

# clear bashrc
sed -i '/ZOOKEEPER/d' ~/.bashrc

# update bashrc
echo "Updating '~/.bashrc'"
echo "" >> ~/.bashrc
echo "# Added by installer - ZOOKEEPER" >> ~/.bashrc
echo "export ZOOKEEPER_HOME=$INSTALL_DIRECTORY/tdss/zookeeper" >> ~/.bashrc
echo "export PATH=\$PATH:\$ZOOKEEPER_HOME/bin" >> ~/.bashrc
echo "" >> ~/.bashrc

source ~/.bashrc

# create data dir
zookeeper_data_dir=$(cat "$INSTALL_DIRECTORY/tdss/zookeeper/conf/zoo.cfg" | grep ^dataDir | cut -d "=" -f 2)
echo "Creating Zookeeper data dir :: $zookeeper_data_dir"
mkdir -p "$zookeeper_data_dir"

# create myid file
echo "Creating 'myid' file under Zookeeper data dir :: myid = $MY_ID"
# touch "$zookeeper_data_dir/myid"
echo "$MY_ID" > "$zookeeper_data_dir/myid"

# start zkServer
echo "Starting Zookeeper Service"
cd $ZOOKEEPER_HOME
sh ./bin/zkServer.sh start
cd $HOME

set +e
