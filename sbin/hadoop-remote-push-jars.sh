echo "############################### -- TDSS :: Hadoop - push jars"

curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
	echo "############################### -- TDSS :: Hadoop - push jars -- $(tput setaf 1)Failed$(tput sgr0)" 
    	exit;
}

# IP format validation function

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

# Start Hadoop
push_jars(){
	echo "$(tput setaf 3)Pushing jars to '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		scp ../libs/spark-jars.tar.gz "$2@$1:~/"
		ssh "$2@$1" 'bash -s' < ../sbin/push_jars_to_hdfs.sh
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../libs/spark-jars.tar.gz "$2@$1:~/"
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/push_jars_to_hdfs.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../libs/spark-jars.tar.gz "$2@$1:~/"
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/push_jars_to_hdfs.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

master=$(cat "$config_file_path" | grep ^HADOOP_MASTER_SERVER | cut -d ":" -f 2)
master_user=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
master_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
master_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

spark_jars_hdfs_dir=$(cat "$config_file_path" | grep ^SPARK_JARS_HDFS_DIR | cut -d ":" -f 2)

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

# Spark jars dir in HDFS
name_fetch_check "$spark_jars_hdfs_dir" "HDFS -" "Spark jars dir"
spark_jars_hdfs_dir_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with server"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
echo "MySQL server  :: $(tput setaf 3) '$master_final' - $master_user_final - $master_access_typ_final - $master_access_tkn_final $(tput sgr0)"
conn_check "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"

## ------------------------------------------------------ Push to HDFS  ------------------------------------------------------

# Update 'jars_dir' in push_jars_to_hdfs.sh
sed -i "/jars_dir=/c\jars_dir=$spark_jars_hdfs_dir_final" ./push_jars_to_hdfs.sh

echo "-------------------------------"
echo "Copying jars to Master server"
push_jars "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
echo "Copying jars to Master server -$(tput setaf 2) Done $(tput sgr0)"

echo "############################### -- TDSS :: Hadoop - push jars -- $(tput setaf 2)Done$(tput sgr0)"