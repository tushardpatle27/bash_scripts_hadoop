#!/bin/bash

source ~/.bashrc

# INSTALL_DIRECTORY will be udated by ../bin/tomee_setup.sh
INSTALL_DIRECTORY=

set -e
## Install TomEE
cd $HOME
mkdir -p "$INSTALL_DIRECTORY/tdss"
if [[ ! -d "$INSTALL_DIRECTORY/tdss/tomee" ]]; then
	echo "Installing TomEE under $INSTALL_DIRECTORY/tdss"
	# untar TomEE
	tar -xf apache-tomee-*.tar.gz
	# move
	tar_file=$(ls -d apache-tomee-*/)
    tar_file_final=${tar_file%/}
	
	mv "$tar_file_final" "$INSTALL_DIRECTORY/tdss/tomee"
	rm apache-tomee-*.tar.gz

else
    echo "TomEE already installed" 
    
    # Clear files (already placed by ../bin/tomee_setup.sh)
	echo "Removing unecessary files"
	rm apache-tomee*.tar.gz
    exit;
fi

# clear bashrc
sed -i '/TOMEE/d' ~/.bashrc

# update bashrc
echo "Updating '~/.bashrc'"
echo "" >> ~/.bashrc
echo "# Added by installer - TOMEE" >> ~/.bashrc
echo "export TOMEE_HOME=$INSTALL_DIRECTORY/tdss/tomee" >> ~/.bashrc
echo "export PATH=\$PATH:\$TOMEE_HOME/bin" >> ~/.bashrc
echo "" >> ~/.bashrc

source ~/.bashrc

# start tomee
echo "Starting TomEE Service"
cd $TOMEE_HOME
sh ./bin/startup.sh
cd $HOME

set +e
