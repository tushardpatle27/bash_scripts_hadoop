#!/bin/bash

echo "############################### -- TDSS :: Zookeeper Service - Stop"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting $(tput sgr0)";
    echo "############################### -- TDSS :: Zookeeper Service - Stop -- $(tput setaf 1)Failed$(tput sgr0)"
    exit 1;
}
exit_s(){
	echo "############################### -- TDSS :: Zookeeper Service - Stop -- $(tput setaf 2)Completed$(tput sgr0)"
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

# Stop Zookeeper
stop_zookeeper(){
	echo "$(tput setaf 3)Stopping Zookeeper in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/stop_zookeeper_quorum.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/stop_zookeeper_quorum.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/stop_zookeeper_quorum.sh
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

zookeeper_server_ip=$(cat "$config_file_path" | grep ^HADOOP_HA_MASTER_SERVERS | cut -d ":" -f 2)
zookeeper_server_username=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
zookeeper_server_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
zookeeper_server_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

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

## ------------------------------------------------------ Stop Zookeeper ------------------------------------------------------

echo "-------------------------------"
# echo "Zookeeper Service"
for srvr in ${zookeeper_server_ip_final[@]}
do
	sed -i "/service=/c\service='zookeeper'" ../sbin/service_status.sh
	res=$(check_service "$srvr" "$zookeeper_server_username_final" "$zookeeper_server_acc_typ_final" "$zookeeper_server_acc_tkn_final" "QuorumPeerMain")
	if [[ $res == *"not running"* ]]; then
		echo "$(tput setaf 3)Server '$srvr'$(tput sgr0)"
		echo "$res"
	else 
		stop_zookeeper "$srvr" "$zookeeper_server_username_final" "$zookeeper_server_acc_typ_final" "$zookeeper_server_acc_tkn_final"
	fi
done
# echo "Zookeeper Service -$(tput setaf 2) Stopped $(tput sgr0)"

## ------------------------------------------------------ Success ------------------------------------------------------

exit_s
