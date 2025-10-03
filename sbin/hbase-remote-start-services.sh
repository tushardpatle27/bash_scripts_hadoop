#!/bin/bash

echo "############################### -- TDSS :: HBase Services - Start"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
    echo "############################### -- TDSS :: HBase Services - Start -- $(tput setaf 1)Failed$(tput sgr0)"
    exit 1;
}
exit_s(){
	echo "############################### -- TDSS :: HBase Services - Start -- $(tput setaf 2)Completed$(tput sgr0)"
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

# Start HBase
start_hbase(){
	echo "$(tput setaf 3)Starting HBase in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/start_hbase_services.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/start_hbase_services.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/start_hbase_services.sh
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
install_directory=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d "=" -f 2)

hbase_server_ip=$(cat "$config_file_path" | grep ^HBASE_SERVER_IP | cut -d ":" -f 2)
hbase_server_username=$(cat "$config_file_path" | grep ^HBASE_SERVER_USERNAME | cut -d ":" -f 2)
hbase_server_auth_mech=$(cat "$config_file_path" | grep ^HBASE_SERVER_AUTH_MECH | cut -d ":" -f 2)
hbase_server_auth_tkn=$(cat "$config_file_path" | grep ^HBASE_SERVER_AUTH_TKN | cut -d ":" -f 2)


name_fetch_check "$hbase_server_ip" "HBase server -" "ip/name"
hbase_server_ip_final="$curr_unm"

name_fetch_check "$hbase_server_username" "HBase server -" "username"
hbase_server_username_final="$curr_unm"

name_fetch_check "$hbase_server_auth_mech" "HBase server -" "access token type"
hbase_server_auth_mech_final="$curr_unm"

password_fetch_check "$hbase_server_auth_tkn" "HBase server -" "access token"
hbase_server_auth_tkn_final="$curr_unm"


## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with servers"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'" 
echo "HBase server  :: $(tput setaf 3) '$hbase_server_ip_final' - $hbase_server_username_final - $hbase_server_auth_mech_final - $hbase_server_auth_tkn_final $(tput sgr0)"
conn_check "$hbase_server_ip_final" "$hbase_server_username_final" "$hbase_server_auth_mech_final" "$hbase_server_auth_tkn_final"

## ------------------------------------------------------ Startup HBase ------------------------------------------------------

echo "-------------------------------"
# echo "HBase Service"
sed -i "/service=/c\service='hbase'" ../sbin/service_status.sh
res=$(check_service "$hbase_server_ip_final" "$hbase_server_username_final" "$hbase_server_auth_mech_final" "$hbase_server_auth_tkn_final" "HMaster")
if [[ $res == *"not running"* ]]; then 
	start_hbase "$hbase_server_ip_final" "$hbase_server_username_final" "$hbase_server_auth_mech_final" "$hbase_server_auth_tkn_final"
else
	echo "$(tput setaf 3)Server '$hbase_server_ip_final'$(tput sgr0)"
	echo "$res"
fi
# echo "HBase Service -$(tput setaf 2) Started $(tput sgr0)"

## ------------------------------------------------------ Success ------------------------------------------------------

exit_s

