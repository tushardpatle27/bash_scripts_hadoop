echo "############################### -- TDSS :: MySQL - Shutdown"

curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
	echo "############################### -- TDSS :: MySQL - Shutdown -- $(tput setaf 1)Failed$(tput sgr0)" 
    	exit;
}

# IP format validation function

# Username and string validation function
name_fetch_check(){
	echo "$2 $3 given: '$1'"
	local unm="$(echo $1 | sed 's/[\%*,&();`{}]//g' | sed 's@[[:blank:]]@@')"
	echo "$2 $3 fetched: '$unm'"
	if [[ ! -z "$unm" ]]; then
		curr_unm="$unm"
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

# Kill MySQL Service
kill_mysql(){
	echo "$(tput setaf 3)Killing MySQL Service in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/kill_mysqld.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/kill_mysqld.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/kill_mysqld.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

mysql_server_ip=$(cat "$config_file_path" | grep ^DATABASE_SERVER_IP | cut -d ":" -f 2)
mysql_server_username=$(cat "$config_file_path" | grep ^DATABASE_SERVER_USERNAME | cut -d ":" -f 2)
mysql_server_acc_typ=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_MECH | cut -d ":" -f 2)
mysql_server_acc_tkn=$(cat "$config_file_path" | grep ^DATABASE_SERVER_AUTH_TKN | cut -d ":" -f 2)

name_fetch_check "$mysql_server_ip" "MySQL server -" "ip/name"
mysql_server_ip_final="$curr_unm"

name_fetch_check "$mysql_server_username" "MySQL server -" "username"
mysql_server_username_final="$curr_unm"

name_fetch_check "$mysql_server_acc_typ" "MySQL server -" "access token type"
mysql_server_acc_typ_final="$curr_unm"

password_fetch_check "$mysql_server_acc_tkn" "MySQL server -" "access token"
mysql_server_acc_tkn_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with servers"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'" 
echo "MySQL server  :: $(tput setaf 3) '$mysql_server_ip_final' - $mysql_server_username_final - $mysql_server_acc_typ_final - $mysql_server_acc_tkn_final $(tput sgr0)"
conn_check "$mysql_server_ip_final" "$mysql_server_username_final" "$mysql_server_acc_typ_final" "$mysql_server_acc_tkn_final"

## ------------------------------------------------------ Kill MySQL Service  ------------------------------------------------------

echo "-------------------------------"
echo "Stopping MySQL Service"
kill_mysql "$mysql_server_ip_final" "$mysql_server_username_final" "$mysql_server_acc_typ_final" "$mysql_server_acc_tkn_final"
echo "Stopping MySQL Service -$(tput setaf 2) Done $(tput sgr0)"

echo "############################### -- TDSS :: MySQL - Shutdown -- $(tput setaf 2)Done$(tput sgr0)"

