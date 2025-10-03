#!/bin/bash

source ~/.bashrc

# INSTALL_DIRECTORY will be udated by ../bin/hbase_with_phoenix_setup.sh
INSTALL_DIRECTORY=/home/ec2-user
new_install_dir="$INSTALL_DIRECTORY/tdss"

# Install HBase with Phoenix
cd $HOME
mkdir -p "$new_install_dir"
mkdir -p "$new_install_dir/hbase-data/hbase"
if [[ ! -d "$new_install_dir/hbase" ]]; then
	set -e
	echo "Deploying HBase under $new_install_dir"
	# untar hbase
	tar -xf hbase-*-bin.tar.gz
	#move
	tar_file=$(ls | grep hbase-*-bin.tar.gz)
    tar_file_final=${tar_file//-bin.tar.gz/}
	mv "$tar_file_final" "$new_install_dir/hbase"
	set +e

else
    echo "HBase already installed" 
    rm hbase-*-bin.tar.gz
    rm hbase-site.xml hbase-env.sh
    # exit;
fi

cd $HOME
mkdir -p "$new_install_dir"
if [[ ! -d "$new_install_dir/phoenix" ]]; then
	set -e
	echo "Deploying Phoenix under $new_install_dir"
	# untar phoenix
	tar -xf phoenix-hbase-*-bin.tar.gz
	#move
	tar_file=$(ls | grep phoenix-hbase-*-bin.tar.gz)
    tar_file_final=${tar_file//.tar.gz/}
	mv "$tar_file_final" "$new_install_dir/phoenix"
	set +e

else
    echo "Phoenix already installed"
    rm phoenix-hbase-*-bin.tar.gz
    exit;
fi

set -e

# clear files
echo "Removing unecessary files"
rm hbase-*-bin.tar.gz
rm phoenix-hbase-*-bin.tar.gz

# clear bashrc
sed -i '/HBASE/d' ~/.bashrc
sed -i '/PHOENIX/d' ~/.bashrc

# update bashrc
echo "Updating '~/.bashrc'"
echo "" >> ~/.bashrc
echo "# Added by installer - HBASE with Phoenix" >> ~/.bashrc
echo "" >> ~/.bashrc
echo "export HBASE_HOME=$new_install_dir/hbase" >> ~/.bashrc
echo "export PATH=\$PATH:\$HBASE_HOME/bin" >> ~/.bashrc
export PATH=$PATH:$HBASE_HOME/bin
echo "" >> ~/.bashrc
echo "export PHOENIX_HOME=$new_install_dir/phoenix" >> ~/.bashrc
echo "export PATH=\$PATH:\$PHOENIX_HOME/bin" >> ~/.bashrc
export PATH=$PATH:$PHOENIX_HOME/bin
source ~/.bashrc

# update conf
echo "Updating 'hbase-site.xml' and 'hbase-env.sh'"
mv hbase-site.xml hbase-env.sh $HBASE_HOME/conf/

# update libs
cp $PHOENIX_HOME/phoenix-*-HBase-*-queryserver.jar $HBASE_HOME/lib/
cp $PHOENIX_HOME/phoenix-*-HBase-*-server.jar $HBASE_HOME/lib/
cp $PHOENIX_HOME/phoenix-*-HBase-*-client.jar $HBASE_HOME/lib/
cp $HBASE_HOME/conf/hbase-site.xml $PHOENIX_HOME/bin/
source ~/.bashrc
# Start HBase
echo "Starting HBase"
cd $HBASE_HOME
./bin/start-hbase.sh start

set +e

