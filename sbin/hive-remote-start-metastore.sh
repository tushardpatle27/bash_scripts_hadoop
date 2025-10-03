#!/bin/bash

echo "############################### -- TDSS :: Hive Metastore - Startup"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting $(tput sgr0)";
    echo "############################### -- TDSS :: Hive Metastore - Startup -- $(tput setaf 1)Failed$(tput sgr0)"
    exit 1;
}
exit_s(){
	echo "############################### -- TDSS :: Hive Metastore - Startup -- $(tput setaf 2)Done$(tput sgr0)"
	exit;
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

# Install Hive
start_hive(){
	echo "$(tput setaf 3)Installing Hive in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/start_hive_metastore.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/start_hive_metastore.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/start_hive_metastore.sh
	fi
	set +e
}

# Check Service
check_service(){
	# echo "$(tput setaf 3) Checking $5 service in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then		
		ssh "$2@$1" 'bash -s' < ../sbin/service_status.sh
	elif [[ $3 == 'KEY' ]]; then		
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/service_status.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/service_status.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

echo "-------------------------------"
echo "Fetching servers details .."
# install_dir=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d "=" -f 2)

hive_server_ip=$(cat "$config_file_path" | grep ^HIVE_METASTORE_SERVERS | cut -d ":" -f 2)
hive_server_username=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
hive_server_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
hive_server_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

# hive_metastore_db_name=$(cat "$config_file_path" | grep ^HIVE_METASTORE_DB | cut -d ":" -f 2)

mysql_server_ip=$(cat "$config_file_path" | grep ^DATABASE_SERVER_IP | cut -d ":" -f 2)
mysql_server_username=$(cat "$config_file_path" | grep ^DATABASE_SERVER_USERNAME | cut -d ":" -f 2)
mysql_server_acc_typ=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_MECH | cut -d ":" -f 2)
mysql_server_acc_tkn=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_TKN | cut -d ":" -f 2)
#
# mysql_user=$(cat "$config_file_path" | grep ^DATABASE_USERNAME | cut -d ":" -f 2)
# mysql_password=$(cat "$config_file_path" | grep ^DATABASE_PASSWORD | cut -d ":" -f 2)
# mysql_port=$(cat "$config_file_path" | grep ^DATABASE_PORT | cut -d ":" -f 2)

master=$(cat "$config_file_path" | grep ^HADOOP_MASTER_SERVER | cut -d ":" -f 2)
master_user=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
master_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
master_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)


#name_fetch_check "$hive_server_ip" "Hive server -" "ip/name"
#hive_server_ip_final="$curr_unm"

# hive_server_ip ip validation
hive_server_ip_final=()
IFS=',' read -ra servers_temp <<< "$hive_server_ip"
for server in "${servers_temp[@]}"
do
        name_fetch_check "$server" "Hive server" "IP"
        hive_server_ip_final+=("$curr_unm")
done


name_fetch_check "$hive_server_username" "Hive server -" "username"
hive_server_username_final="$curr_unm"

name_fetch_check "$hive_server_acc_typ" "Hive server -" "access token type"
hive_server_acc_typ_final="$curr_unm"

password_fetch_check "$hive_server_acc_tkn" "Hive server -" "access token"
hive_server_acc_tkn_final="$curr_unm"

# name_fetch_check "$install_dir" "Hive installation" "dir"
# install_dir_final="$curr_unm"

# name_fetch_check "$hive_metastore_db_name" "Hive" "metastore db"
# hive_metastore_db_name_final="$curr_unm"

#####
name_fetch_check "$mysql_server_ip" "MySQL server -" "ip/name"
mysql_server_ip_final="$curr_unm"

name_fetch_check "$mysql_server_username" "MySQL server -" "username"
mysql_server_username_final="$curr_unm"

name_fetch_check "$mysql_server_acc_typ" "MySQL server -" "access token type"
mysql_server_acc_typ_final="$curr_unm"

password_fetch_check "$mysql_server_acc_tkn" "MySQL server -" "access token"
mysql_server_acc_tkn_final="$curr_unm"
#
# name_fetch_check "$mysql_user" "MySQL" "user"
# mysql_user_final="$curr_unm"

# name_fetch_check "$mysql_password" "MySQL" "password"
# mysql_password_final="$curr_unm"

# name_fetch_check "$mysql_port" "MySQL" "port"
# mysql_port_final="$curr_unm"

######
name_fetch_check "$master" "Master" "ip/name"
master_final="$curr_unm"

name_fetch_check "$master_user" "Master" "username"
master_user_final="$curr_unm"

name_fetch_check "$master_acc_typ" "Master" "access-type"
master_access_typ_final="$curr_unm"

password_fetch_check "$master_acc_tkn" "Master" "access-token"
master_access_tkn_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------
echo "-------------------------------"
echo "Checking connectivity with server"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
count=-1
for server in ${hive_server_ip_final[@]}
do
             count=$((count+=1))
             echo "Hive server  :: $(tput setaf 3) '$server'  - $hive_server_username_final - $hive_server_acc_typ_final - $hive_server_acc_tkn_final $(tput sgr0)"
            conn_check "$server" "$hive_server_username_final" "$hive_server_acc_typ_final" "$hive_server_acc_tkn_final"
done

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

## ------------------------------------------------------ Check MySQL and Hadoop and Hive ------------------------------------------------------

#echo "-------------------------------"
#echo "Service check"
# MySQL Service
#echo "$(tput setaf 3) Checking MySQLd service in '$mysql_server_ip_final'$(tput sgr0)"
#sed -i "/service=/c\service='mysqld'" ../sbin/service_status.sh
#res=$(check_service "$mysql_server_ip_final" "$mysql_server_username_final" "$mysql_server_acc_typ_final" "$mysql_server_acc_tkn_final")
#if [[ $res == *"not running"* ]]; then echo "not running"; exit_f; else echo "$res"; fi

# Hadoop (HDFS) Service
echo "$(tput setaf 3) Checking HDFS service in '$master_final'$(tput sgr0)"
sed -i "/service=/c\service='hadoop'" ../sbin/service_status.sh
res=$(check_service "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final")
if [[ $res == *"not running"* ]]; then echo "not running"; exit_f; else echo "Running"; fi

# Hive
#echo "$(tput setaf 3) Checking Hive service in '${hive_server_ip_final[@]}'$(tput sgr0)"
#sed -i "/service=/c\service='hive'" ../sbin/service_status.sh
#res=$(check_service "${hive_server_ip_final[@]}" "$hive_server_username_final" "$hive_server_acc_typ_final" "$hive_server_acc_tkn_final")
#if [[ $res != *"not running"* ]]; then echo "$res"; exit_f; else echo "$res"; fi

#echo "Service check -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Start Hive Metastore ------------------------------------------------------

echo "-------------------------------"
echo "Hive Starting"
for server in ${hive_server_ip_final[@]}
do
        start_hive "$server" "$hive_server_username_final" "$hive_server_acc_typ_final" "$hive_server_acc_tkn_final"
done
echo "Hivestarting - $(tput setaf 2)Done$(tput sgr0)"

# Exit "Success"
exit_s

