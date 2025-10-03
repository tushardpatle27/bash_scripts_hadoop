#!/bin/bash

source ~/.bashrc

# INSTALL_DIRECTORY will be udated by ../bin/hadoop_setup.sh
INSTALL_DIRECTORY=/home/ec2-user
new_install_dir="$INSTALL_DIRECTORY/tdss"

# Install MySQL
cd $HOME
mkdir -p "$new_install_dir"
if [[ ! -d "$new_install_dir/mysql" ]]; then
	set -e
	echo "Installing MySQL under $new_install_dir"
	# untar mysql
	tar -xf mysql*.tar.gz
	#move
	tar_file=$(ls | grep mysql*.tar.gz)
    tar_file_final=${tar_file//.tar.gz/}
	mv "$tar_file_final" "$new_install_dir/mysql"
	set +e

	# install libaio*.rpm
	#echo "installing libaio-0 package"
	#echo "y" | sudo rpm -ivh libaio*.rpm 

	mv my.cnf "$new_install_dir/mysql/"
	# mv my.ini "$new_install_dir/mysql/"

else
    echo "MySQL already installed" 
    rm mysql*.tar.gz
    rm my.cnf
    #rm libaio*.rpm
    exit;
fi

set -e

# clear files
echo "Removing unecessary files"
rm mysql*.tar.gz
#rm libaio*.rpm

# clear bashrc
sed -i '/MYSQL/d' ~/.bashrc

# update bashrc
echo "Updating '~/.bashrc'"
echo "" >> ~/.bashrc
echo "# Added by installer - MYSQL" >> ~/.bashrc
echo "" >> ~/.bashrc
echo "export MYSQL_HOME=$new_install_dir/mysql" >> ~/.bashrc
echo "export PATH=\$PATH:\$MYSQL_HOME/bin" >> ~/.bashrc
source ~/.bashrc

cd $MYSQL_HOME
mkdir data

# update my.cnf
echo "Updating 'my.cnf' file"
sed -i "/basedir=/c\basedir=$new_install_dir/mysql" ./my.cnf
sed -i "/datadir=/c\datadir=$new_install_dir/mysql/data" ./my.cnf
sed -i "/socket=/c\socket=$new_install_dir/mysql/mysql.sock" ./my.cnf

# Init MySQL
echo "Initializing MySQL"
./bin/mysqld --defaults-file=./my.cnf --initialize --datadir="$new_install_dir"/mysql/data --lc-messages-dir="$new_install_dir"/mysql/share/english &> mysqld_init_log
def_psswd=$(cat mysqld_init_log | grep root@localhost: | tr ' ' '\n' | tail -1)
echo "$def_psswd" > default_password
echo "Password generated: '$def_psswd'"

## First start
echo "Starting 'mysqld'"
nohup ./bin/mysqld --defaults-file=./my.cnf --user=root > curr_log_file 2>&1 &
sleep 5
cat curr_log_file

pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | tail -1 | awk '{print $2}')
# validate
if grep -q "ready for connections" curr_log_file; then
	echo "'mysqld' is initiated on PID - '$pid_num'"
else
	echo "'mysqld' is not ready for connections"
	exit 1;
fi

# get mysql user, password, port and database name
new_user=$(cat ./my.cnf | grep ^user= | cut -d "=" -f 2)
new_psswd=$(cat ./my.cnf | grep ^#password= | cut -d "=" -f 2)
new_port=$(cat ./my.cnf | grep ^port= | cut -d "=" -f 2)
new_db_name=$(cat ./my.cnf | grep ^#database_name= | cut -d "=" -f 2)
hive_metastore=$(cat ./my.cnf | grep ^#hive_metastore= | cut -d "=" -f 2)

# generate sql file
echo "Generating temp.sql file"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$def_psswd';" > temp.sql
echo "FLUSH PRIVILEGES;" >> temp.sql
echo "GRANT ALL PRIVILEGES ON * . * TO 'root'@'localhost';" >> temp.sql
#echo "CREATE USER '$new_user'@'127.0.0.1' IDENTIFIED BY '$new_psswd';" >> temp.sql
#echo "GRANT ALL PRIVILEGES ON * . * TO '$new_user'@'127.0.0.1';" >> temp.sql
echo "GRANT ALL PRIVILEGES ON *.* TO '$new_user'@'%' IDENTIFIED BY '$new_psswd' WITH GRANT OPTION;" >> temp.sql
echo "FLUSH PRIVILEGES;" >> temp.sql
#echo "exit;" >> temp.sql

echo "Creating '$new_user' user and updating privileges"
# ./bin/mysql --defaults-file=./my.cnf -u root --connect-expired-password --password="$def_psswd" < ./temp.sql
MYSQL_PWD=`cat default_password` ./bin/mysql --defaults-file=./my.cnf -u root --connect-expired-password < ./temp.sql

# generate sql file - 'create database under given user'
echo "CREATE DATABASE $new_db_name;" > temp2.sql
echo "GRANT ALL PRIVILEGES ON $new_db_name.* TO '$new_user'@'%' WITH GRANT OPTION;" >> temp2.sql
echo "CREATE DATABASE $hive_metastore;" >> temp2.sql
echo "GRANT ALL PRIVILEGES ON $hive_metastore.* TO '$new_user'@'%' WITH GRANT OPTION;" >> temp2.sql
echo "FLUSH PRIVILEGES;" >> temp2.sql

echo " Creating '$new_db_name' and '$hive_metastore' databases under '$new_user' user"
# ./bin/mysql --defaults-file=./my.cnf -u "$new_user" --connect-expired-password --password="$new_psswd" < ./temp2.sql
MYSQL_PWD=`echo "$new_psswd"` ./bin/mysql --defaults-file=./my.cnf -u "$new_user" < ./temp2.sql

echo "-------------------------------"
echo "User and database successfully created"
echo "User:'$new_user' -- Password:'$new_psswd' -- Host:'%' -- Port:'$new_port' -- databases: '$new_db_name', '$hive_metastore'"

# Restart mysqld
pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | awk '{print $2}')
kill -9 "$pid_num"
sleep 5

echo "-------------------------------"
echo "Restarting MySQL (mysqld)"
nohup ./bin/mysqld > curr_log_file 2>&1 &
sleep 5
cat curr_log_file

pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | tail -1 | awk '{print $2}')
# validate
if grep -q "ready for connections" curr_log_file; then
	echo "Restarted and 'mysqld' is initiated on PID - '$pid_num'"
else
	echo "'mysqld' is not ready for connections"
	echo "Killing '$pid_num'"
	kill -9 "$pid_num"
	exit 1;
fi
exit;
set +e
