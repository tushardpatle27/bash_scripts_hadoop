#!/bin/bash
echo "############################### -- TDSS :: Hadoop - stop all"

curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
	echo "############################### -- TDSS :: Hadoop - stop all -- $(tput setaf 1)Failed$(tput sgr0)"
	exit 1;
}

# IP format validation function
# ip_fetch_check(){
# 	echo "$2 IP given: '$1'"
# 	local mip="$(echo $1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')"
# 	local mip_c="$(echo $mip | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')"
# 	echo "$2 IP fetched: '$mip_c'"
# 	if [[ ("$mip" == "$mip_c") && (! -z "$mip_c") ]]; then
# 	    echo "$2 IP: '$mip_c' - $(tput setaf 2) Valid $(tput sgr0)"
# 	    curr_ip="$mip_c"
# 	else
# 	    echo "$2 IP: '$1' - $(tput setaf 1) Not valid $(tput sgr0)"
# 	    echo "Please correct the '$2' IP address"
# 	    exit_f
# 	fi
# }

# ip_fetch_check(){
# 	echo "$2 $3 given: '$1'"
# 	local mip="$(echo $1 | sed 's/[\%*,&();`{}]//g' | sed 's@[[:blank:]]@@')"
# 	echo "$2 $3 fetched: '$mip'"
# 	if [[ ! -z "$mip" ]]; then
# 		curr_ip="$mip"
# 	else
#         echo "$2 $3: '$1' - $(tput setaf 1) Not valid $(tput sgr0)"
#         echo "Please correct the '$2' $3"
#         exit_f
# 	fi
# }

# Username and string validation function
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

# Stop Hadoop
stop_hadoop(){
	echo "$(tput setaf 3)Stopping Hadoop (DFS & YARN) in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/stop_hadoop.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/stop_hadoop.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/stop_hadoop.sh
	fi
	set +e
}

stop_jobhist(){
	echo "$(tput setaf 3)Stopping JobHistory Server in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/stop_hadoop_jobhist.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/stop_hadoop_jobhist.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/stop_hadoop_jobhist.sh
	fi
	set +e
}

# JPS
jps(){
	echo "$(tput setaf 3)JPS in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" jps
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" jps
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" jps
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

master=$(cat "$config_file_path" | grep ^HADOOP_MASTER_SERVER | cut -d ":" -f 2)
master_user=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
master_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
master_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

#  master ip validation
name_fetch_check "$master" "Master"
master_final="$curr_unm"

#  master access with user
name_fetch_check "$master_user" "Master" "username"
master_user_final="$curr_unm"

#  master access token
name_fetch_check "$master_acc_typ" "Master" "access-type"
master_access_typ_final="$curr_unm"
password_fetch_check "$master_acc_tkn" "Master" "access-token"
master_access_tkn_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with server"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
echo "MySQL server  :: $(tput setaf 3) '$master_final' - $master_user_final - $master_access_typ_final - $master_access_tkn_final $(tput sgr0)"
conn_check "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"

## ------------------------------------------------------ Stop Hadoop  ------------------------------------------------------

echo "-------------------------------"
echo "Stopping Hadoop Services"
stop_hadoop "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
stop_jobhist "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
jps "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
echo "Stopping Hadoop Services -$(tput setaf 2) Done $(tput sgr0)"

echo "############################### -- TDSS :: Hadoop - stop all -- $(tput setaf 2)Done$(tput sgr0)"

