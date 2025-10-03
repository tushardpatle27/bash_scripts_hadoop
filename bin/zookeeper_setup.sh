#!/bin/bash

echo "############################### -- TDSS :: Zookeeper Deployment"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
    echo "############################### -- TDSS :: Zookeeper Deployment -- $(tput setaf 1)Failed$(tput sgr0)"
    exit 1;
}
exit_s(){
	echo "-------------------------------"
	echo "Use the following scripts which are under 'sbin' dir to start and stop Zookeeper"
	echo "To Start -$(tput setaf 2) zookeeper-remote-start-quorum.sh $(tput sgr0)"
	echo "To Stop -$(tput setaf 2) zookeeper-remote-stop-quorum.sh $(tput sgr0)"
	echo "############################### -- TDSS :: Zookeeper Deployment -- $(tput setaf 2)Completed$(tput sgr0)"
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

# Install Zookeeper
install_zookeeper(){
	echo "$(tput setaf 3)Installing Zookeeper in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		scp ../libs/apache-zookeeper-*.tar.gz "$2@$1:~/"
		scp ../conf/zookeeper/generated_zookeeper_config/* "$2@$1:~/"
		
		ssh "$2@$1" 'bash -s' < ../sbin/install_zookeeper.sh
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../libs/apache-zookeeper-*.tar.gz "$2@$1:~/"
		scp -i "$4" ../conf/zookeeper/generated_zookeeper_config/* "$2@$1:~/"
		
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/install_zookeeper.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../libs/apache-zookeeper-*.tar.gz "$2@$1:~/"
		sshpass -p "$4" scp ../conf/zookeeper/generated_zookeeper_config/* "$2@$1:~/"

		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/install_zookeeper.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

echo "-------------------------------"
echo "Fetching servers details .."
install_dir=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d ":" -f 2 | sed 's/ //')

zookeeper_server_ip=$(cat "$config_file_path" | grep ^HADOOP_HA_MASTER_SERVERS | cut -d ":" -f 2)
zookeeper_server_username=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
zookeeper_server_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
zookeeper_server_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

zookeeper_data_dir=$(cat "$config_file_path" | grep ^ZOOKEEPER_DATA_DIR | cut -d ":" -f 2)


zookeeper_server_ip_final=()
IFS=',' read -ra zk_temp <<< "$zookeeper_server_ip"
for zk in "${zk_temp[@]}" 
do
 	name_fetch_check "$zk" "Zookeeper" "server"
 	zookeeper_server_ip_final+=("$curr_unm")
done

name_fetch_check "$zookeeper_server_username" "Zookeeper server -" "username"
zookeeper_server_username_final="$curr_unm"

name_fetch_check "$zookeeper_server_acc_typ" "Zookeeper server -" "access token type"
zookeeper_server_acc_typ_final="$curr_unm"

password_fetch_check "$zookeeper_server_acc_tkn" "Zookeeper server -" "access token"
zookeeper_server_acc_tkn_final="$curr_unm"

name_fetch_check "$install_dir" "Zookeeper installation" "dir"
install_dir_final="$curr_unm"

name_fetch_check "$zookeeper_data_dir" "Zookeeper" "data dir"
zookeeper_data_dir_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with server"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"

count=-1 
for srvr in ${zookeeper_server_ip_final[@]}
do
	count=$((count+=1))
	echo "Server Details :: $(tput setaf 3) '${zookeeper_server_ip_final[$count]}' - $zookeeper_server_username_final - $zookeeper_server_acc_typ_final - $zookeeper_server_acc_tkn_final $(tput sgr0)"
	conn_check "${zookeeper_server_ip_final[$count]}" "$zookeeper_server_username_final" "$zookeeper_server_acc_typ_final" "$zookeeper_server_acc_tkn_final"
done

## ------------------------------------------------------ Confirm and continue  ------------------------------------------------------

#echo "-------------------------------"
3while true 
#do
#    read -p "Okay to continue.. ::(y/n)" choice
#    case "$choice" in
#      y|Y ) echo "$(tput setaf 2)Installation resumed$(tput sgr0)"; break;;
#      n|N ) exit_f;;
#      * ) echo "Invalid entry"; continue;;
#    esac
#done

## ------------------------------------------------------ Generate Zookeeper configuration  ------------------------------------------------------

echo "-------------------------------"
echo "Generating Zookeeper configuration"

if [[ ! -z "$(ls -A ../conf/zookeeper/generated_zookeeper_config/)" ]]; then
	echo "Clearing pre-generated zookeeper configuration"
	rm ../conf/zookeeper/generated_zookeeper_config/*
fi

cp ../conf/zookeeper/config_template/zoo.cfg ../conf/zookeeper/generated_zookeeper_config
sed -i "s@#ZOOKEEPER_DATA_DIR#@$zookeeper_data_dir_final@" ../conf/zookeeper/generated_zookeeper_config/zoo.cfg

num=0
for srvr in ${zookeeper_server_ip_final[@]}
do
	num=$((num+=1))
	echo "server.$num=$srvr:2888:3888" >> ../conf/zookeeper/generated_zookeeper_config/zoo.cfg
done

# update sbin/install_zookeeper.sh with install_dir
set -e
sed -i "s|INSTALL_DIRECTORY=.*|INSTALL_DIRECTORY=$install_dir_final|g" ../sbin/install_zookeeper.sh
set +e

echo "Generating Zookeeper configuration -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Install Zookeeper ------------------------------------------------------

echo "-------------------------------"
echo "Zookeeper Installation"
myid=0
for srvr in ${zookeeper_server_ip_final[@]}
do
	myid=$((myid+=1))
	sed -i "s|MY_ID=.*|MY_ID=$myid|g" ../sbin/install_zookeeper.sh
	install_zookeeper "$srvr" "$zookeeper_server_username_final" "$zookeeper_server_acc_typ_final" "$zookeeper_server_acc_tkn_final"
done
echo "Zookeeper Installation -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Success ------------------------------------------------------
exit_s

