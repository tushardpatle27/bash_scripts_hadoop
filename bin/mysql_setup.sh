#!/bin/bash

echo "############################### -- TDSS :: MySQL Deployment"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

sudo yum install -y libncurses*
sudo yum install -y libaio

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
    echo "############################### -- TDSS :: MySQL Deployment -- $(tput setaf 1)Failed$(tput sgr0)"
    exit 1;
}

# Trim string and validate
name_fetch_check(){
	echo "$2 $3 given: '$1'"
	local unm="$(echo $1 | sed 's/[\%*,&();`{}]//g' | sed 's@[[:blank:]]@@')"
	echo "$2 $3 fetched: '${unm%/}'"
	if [[ ! -z "$unm" ]]; then
		curr_unm="${unm%/}"
	else
        echo "$2 $3: '$1' - $(tput setaf 1) Not valid $(tput sgr0)"
        echo "Please correct the '$2' $3"
        exit_f
	fi
}

# Password and string validation function
password_fetch_check(){
	echo "$2 $3 given: '$1'"
	local unm="$(echo $1 | sed 's@[[:blank:]]@@')"
	echo "$2 $3 fetched: '$unm'"
	if [[ ! -z "$unm" ]]; then
		curr_unm="$unm"
	else
        echo "$2 $3: '$1' - $(tput setaf 1) Not valid $(tput sgr0)"
        echo "Please correct the '$2' $3"
        exit_f
	fi
}

# Check connectivity
conn_check(){
	# echo "$1 $2 $3 $4"
	if [[ "$3" == "NIL" ]]; then
		ssh -o ConnectTimeout=3 "$2@$1" echo 'connected'
		if [[ ! "$?" -eq 0 ]]; then 
			echo "Entered wrong password"; exit_f;
		# # else
		# #	sshpass -p "$4" ssh-copy-id "$2@$1"
		fi

	elif [[ "$3" == "KEY" ]]; then
		# sshpass -f "$4" ssh -o ConnectTimeout=2 "$2@$1" echo 'connected'
		ssh -i "$4" -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$2@$1" echo 'connected'
		if [[ ! "$?" -eq 0 ]]; then 
			echo "Unable to access $1 with $4 as $2" ; exit_f;
		# else
		# 	sshpass -f "$4" ssh-copy-id "$2@$1"
		fi

	elif [[ "$3" == "PASS" ]]; then
		sshpass -p "$4" ssh -o ConnectTimeout=3 "$2@$1" echo 'connected'
		if [[ ! "$?" -eq 0 ]]; then 
			echo "Entered wrong password"; exit_f;
		# else
		# 	sshpass -p "$4" ssh-copy-id "$2@$1"
		fi
	else
		echo "unexpected token type"; exit_f;
	fi
}

# Install MySQL
install_mysql(){
	echo "$(tput setaf 3)Installing MySQL in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		scp ../libs/mysql*.tar.gz "$2@$1:~/"
		#scp ../libs/libaio*.rpm "$2@$1:~/"
		scp ../conf/mysql/my.cnf "$2@$1:~/"
		ssh "$2@$1" 'bash -s' < ../sbin/install_mysql.sh
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../libs/mysql*.tar.gz "$2@$1:~/"
		#scp -i "$4" ../libs/libaio*.rpm "$2@$1:~/"
		scp -i "$4" ../conf/mysql/my.cnf "$2@$1:~/"
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/install_mysql.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../libs/mysql*.tar.gz "$2@$1:~/"
		#sshpass -p "$4" scp ../libs/libaio*.rpm "$2@$1:~/"
		sshpass -p "$4" ../conf/mysql/my.cnf "$2@$1:~/"
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/install_mysql.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

echo "-------------------------------"
echo "Fetching servers details .."
install_dir=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d "=" -f 2)

mysql_server_ip=$(cat "$config_file_path" | grep ^DATABASE_SERVER_IP | cut -d ":" -f 2)
mysql_server_username=$(cat "$config_file_path" | grep ^DATABASE_SERVER_USERNAME | cut -d ":" -f 2)
mysql_server_acc_typ=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_MECH | cut -d ":" -f 2)
mysql_server_acc_tkn=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_TKN | cut -d ":" -f 2)

mysql_user=$(cat "$config_file_path" | grep ^DATABASE_USERNAME | cut -d ":" -f 2)
mysql_password=$(cat "$config_file_path" | grep ^DATABASE_PASSWORD | cut -d ":" -f 2)
mysql_port=$(cat "$config_file_path" | grep ^DATABASE_PORT | cut -d ":" -f 2)

mysql_database_name=$(cat "$config_file_path" | grep ^DATABASE_NAME | cut -d ":" -f 2)
hive_metastore_db_name=$(cat "$config_file_path" | grep ^HIVE_METASTORE_DB | cut -d ":" -f 2)

name_fetch_check "$mysql_server_ip" "MySQL server -" "ip/name"
mysql_server_ip_final="$curr_unm"

name_fetch_check "$mysql_server_username" "MySQL server -" "username"
mysql_server_username_final="$curr_unm"

name_fetch_check "$mysql_server_acc_typ" "MySQL server -" "access token type"
mysql_server_acc_typ_final="$curr_unm"

password_fetch_check "$mysql_server_acc_tkn" "MySQL server -" "access token"
mysql_server_acc_tkn_final="$curr_unm"

name_fetch_check "$mysql_user" "MySQL" "user"
mysql_user_final="$curr_unm"

password_fetch_check "$mysql_password" "MySQL" "password"
mysql_password_final="$curr_unm"

name_fetch_check "$mysql_port" "MySQL" "port"
mysql_port_final="$curr_unm"

name_fetch_check "$install_dir" "MySQL installation" "dir"
install_dir_final="$curr_unm"

name_fetch_check "$mysql_database_name" "MySQL" "- database name"
mysql_database_name_final="$curr_unm" 

name_fetch_check "$hive_metastore_db_name" "Hive" "metastore db"
hive_metastore_db_name_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with servers"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'" 
echo "MySQL server  :: $(tput setaf 3) '$mysql_server_ip_final' - $mysql_server_username_final - $mysql_server_acc_typ_final - $mysql_server_acc_tkn_final $(tput sgr0)"
conn_check "$mysql_server_ip_final" "$mysql_server_username_final" "$mysql_server_acc_typ_final" "$mysql_server_acc_tkn_final"

## ------------------------------------------------------ Confirm and continue  ------------------------------------------------------

# echo "-------------------------------"
# while true 
# do
#     read -p "Okay to continue.. :: (y/n)?" choice
#     case "$choice" in
#       y|Y ) echo "$(tput setaf 2)Installation resumed$(tput sgr0)"; break;;
#       n|N ) exit_f;;
#       * ) echo "Invalid entry"; continue;;
#     esac
# done

## ------------------------------------------------------ Generate config ------------------------------------------------------
# edit my.cnf
echo "-------------------------------"
echo "Generating config"
sed -i "/user=/c\user=$mysql_user_final" ../conf/mysql/my.cnf
sed -i "/#password=/c\#password=$mysql_password_final" ../conf/mysql/my.cnf
sed -i "/port=/c\port=$mysql_port_final" ../conf/mysql/my.cnf

sed -i "/#database_name=/c\#database_name=$mysql_database_name_final" ../conf/mysql/my.cnf
sed -i "/#hive_metastore=/c\#hive_metastore=$hive_metastore_db_name_final" ../conf/mysql/my.cnf

## ------------------------------------------------------ Push and install MySQL  ------------------------------------------------------

# update sbin/install_mysql.sh with install_dir

sed -i "s|INSTALL_DIRECTORY=.*|INSTALL_DIRECTORY=$install_dir_final|g" ../sbin/install_mysql.sh

echo "-------------------------------"
echo "MySQL Installation"
install_mysql "$mysql_server_ip_final" "$mysql_server_username_final" "$mysql_server_acc_typ_final" "$mysql_server_acc_tkn_final"
echo "MySQL Installation -$(tput setaf 2) Done $(tput sgr0)"

echo "############################### -- TDSS :: MySQL Deployment -- $(tput setaf 2)Completed$(tput sgr0)"
