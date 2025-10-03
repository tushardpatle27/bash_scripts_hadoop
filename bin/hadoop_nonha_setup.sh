#!/bin/bash

echo "############################### -- TDSS :: Hadoop Deployment"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting installation$(tput sgr0)";
    	echo "############################### -- TDSS :: Hadoop Deployment -- $(tput setaf 1)Installation Failed$(tput sgr0)"
    	exit 1;
}
exit_s(){
	echo "-------------------------------"
	echo "Use the following scripts which are under 'sbin' dir to start and stop Hadoop"
	echo "To Start -$(tput setaf 2) hadoop-remote-start.sh $(tput sgr0)"
	echo "To Stop -$(tput setaf 2) hadoop-remote-stop.sh $(tput sgr0)"

	echo "Use the following script which is under 'sbin' dir to push Sprark libs to HDFS"
	echo "To push jars -$(tput setaf 2) hadoop-remote-push-jars.sh $(tput sgr0)"

	echo "############################### -- TDSS :: Hadoop Deployment -- $(tput setaf 2)Completed$(tput sgr0)"
	exit;
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

ip_fetch_check(){
	echo "$2 $3 given: '$1'"
	local mip="$(echo $1 | sed 's/[\%*,&();`{}]//g' | sed 's@[[:blank:]]@@')"
	echo "$2 $3 fetched: '$mip'"
	if [[ ! -z "$mip" ]]; then
		curr_ip="$mip"
	else
        echo "$2 $3: '$1' - $(tput setaf 1) Not valid $(tput sgr0)"
        echo "Please correct the '$2' $3"
        exit_f
	fi
}

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

iter_func_name_trim(){
    final_temp_array=()
    local count=0
    IFS=', ' read -ra temp_array <<< "$1"
    for val in "${temp_array[@]}"
    do
        name_fetch_check "$val" "$2 $((count+=1))" "$3"
        final_temp_array+=("$curr_unm")
    done
}

# validate_servers(){
#         local ip=$1
#         echo "${ip[@]}"
#         local uname=("$2")
#         local acc_type=("$3")
#         local acc_tkn=("$4")

#         local count=0
#         echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
#         for srvr in ${ip[@]}
#         do
#                 echo "Server '$srvr' :: $(tput setaf 3) '${ip[$count]}' - ${uname[$count]} - ${acc_type[$count]} - ${acc_tkn[$count]} $(tput sgr0)"
#                 count=$((count+1))
#         done 
# }

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

# Establish connectivity with rest
conn_est(){
	# generate rsa
	set -e
	echo "Generating ssh key in $1"
	if [[ "$3" == "NIL" ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/generate_ssh.sh
		mkey=$(ssh "$2@$1" 'bash -s' < ../sbin/get_ssh.sh)
	elif [[ "$3" == "KEY" ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/generate_ssh.sh
		mkey=$(ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/get_ssh.sh)
	elif [[ "$3" == "PASS" ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/generate_ssh.sh
		mkey=$(sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/get_ssh.sh)
	else
		echo "unexpected token type"; exit_f;
	fi

	echo "$mkey" > ../temp/temp_ssh_key
	
	# copy to slaves
	c=-1
	for s in ${slaves_final[@]}
	do
		c=$((c+=1))
		echo "Copying public_key that has been generated in Master '$1' to Slave '$s'"
		if [[ $1 == $s ]]; then echo "same server, skipping.. "; continue; fi
		
		if [[ ${slaves_acc_typ_final[$c]} == 'NIL' ]]; then
			scp ../temp/temp_ssh_key "${slaves_user_final[$c]}@$s:~/master_ssh_key"
			ssh "${slaves_user_final[$c]}@$s" 'bash -s' < ../sbin/put_ssh.sh
		elif [[ ${slaves_acc_typ_final[$c]} == 'KEY' ]]; then
			scp -i "${slaves_acc_tkn_final[$c]}" ../temp/temp_ssh_key "${slaves_user_final[$c]}@$s:~/master_ssh_key"
			ssh -i "${slaves_acc_tkn_final[$c]}" "${slaves_user_final[$c]}@$s" 'bash -s' < ../sbin/put_ssh.sh
		elif [[ ${slaves_acc_typ_final[$c]} == 'PASS' ]]; then
			sshpass -p "${slaves_acc_tkn_final[$c]}" scp ../temp/temp_ssh_key "${slaves_user_final[$c]}@$s:~/master_ssh_key"
			sshpass -p "${slaves_acc_tkn_final[$c]}" ssh "${slaves_user_final[$c]}@$s" 'bash -s' < ../sbin/put_ssh.sh
		fi
	done
	set +e
	echo "$(tput setaf 2)Generated and copied $(tput sgr0)"
}

# Install Hadoop
install_hadoop(){
	set -e
	echo "$(tput setaf 3)Installing hadoop in '$1'$(tput sgr0)"
	if [[ $3 == 'NIL' ]]; then
		scp ../libs/hadoop*.tar.gz "$2@$1:~/"
		ssh "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../libs/hadoop*.tar.gz "$2@$1:~/"
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../libs/hadoop*.tar.gz "$2@$1:~/"
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	fi
	set +e
}

# Update hadoop config
update_hadoop_conf(){
	echo "$(tput setaf 3)Updating hadoop configuration in '$1'$(tput sgr0)"
	if [[ $3 == 'NIL' ]]; then
		scp ../conf/hadoop/generated_hadoop_config/* "$2@$1:$install_dir_final/tdss/hadoop/etc/hadoop/"
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../conf/hadoop/generated_hadoop_config/* "$2@$1:$install_dir_final/tdss/hadoop/etc/hadoop/"
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../conf/hadoop/generated_hadoop_config/* "$2@$1:$install_dir_final/tdss/hadoop/etc/hadoop/"
	fi
}

# Hadoop namenode format
namenode_format(){
	echo "$(tput setaf 3)Formatting Hadoop NameNode in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/format_namenode.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/format_namenode.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/format_namenode.sh
	fi
	set +e
}

# Start Hadoop
start_hadoop(){
	echo "$(tput setaf 3)Starting Hadoop in '$1'$(tput sgr0)"
	set -e
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" 'bash -s' < ../sbin/start_hadoop.sh
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/start_hadoop.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/start_hadoop.sh
	fi
	set +e
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

echo "-------------------------------"
echo "Fetching servers details .."
install_dir=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d "=" -f 2)

master=$(cat "$config_file_path" | grep ^HADOOP_MASTER_SERVER | cut -d ":" -f 2)
slaves=$(cat "$config_file_path" | grep ^HADOOP_SLAVE_SERVERS | cut -d ":" -f 2)

master_user=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
# slaves_user=$(cat "$config_file_path" | grep ^slave_servers_users= | cut -d "=" -f 2)

master_acc_typ=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
# slaves_acc_typ=$(cat "$config_file_path" | grep ^slaves_acc_typ= | cut -d "=" -f 2)

master_acc_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)
# slaves_acc_tkn=$(cat "$config_file_path" | grep ^slaves_acc_tkn= | cut -d "=" -f 2)

namenode_dir=$(cat "$config_file_path" | grep ^HADOOP_META_DIR | cut -d ":" -f 2)
datanode_dir=$(cat "$config_file_path" | grep ^HADOOP_DATA_DIR | cut -d ":" -f 2)
hadoop_temp_dir=$(cat "$config_file_path" | grep ^HADOOP_TEMP_DIR | cut -d ":" -f 2)

#  master ip validation
ip_fetch_check "$master" "Master"
master_final="$curr_ip"

# slaves ip validation
slaves_final=()
IFS=',' read -ra slaves_temp <<< "$slaves"
for slave in "${slaves_temp[@]}" 
do
 	ip_fetch_check "$slave" "Slave"
 	slaves_final+=("$curr_ip")
done

#  master access with user
name_fetch_check "$master_user" "Master" "username"
master_user_final="$curr_unm"

#  slaves access with user
# iter_func_name_trim "$slaves_user" "Slave" "username"
# slaves_user_final=("${final_temp_array[@]}")

slaves_user_final=()
for srvr in ${slaves_final[@]}
do
	slaves_user_final+=("$master_user_final")
done

#  master access token
name_fetch_check "$master_acc_typ" "Master" "access-type"
master_access_typ_final="$curr_unm"
password_fetch_check "$master_acc_tkn" "Master" "access-token"
master_access_tkn_final="$curr_unm"

#  slaves access tokens
# iter_func_name_trim "$slaves_acc_typ" "Slave" "username"
# slaves_acc_typ_final=("${final_temp_array[@]}")

# iter_func_name_trim "$slaves_acc_tkn" "Slave" "username"
# slaves_acc_tkn_final=("${final_temp_array[@]}")

slaves_acc_typ_final=()
for srvr in ${slaves_final[@]}
do
	slaves_acc_typ_final+=("$master_access_typ_final")
done

slaves_acc_tkn_final=()
for srvr in ${slaves_final[@]}
do
	slaves_acc_tkn_final+=("$master_access_tkn_final")
done

# namenode, datanode and temporary dir
name_fetch_check "$namenode_dir" "Namenode" "dir"
namenode_dir_final="$curr_unm"

# name_fetch_check "$datanode_dir" "Datanode" "dir"
# datanode_dir_final="$curr_unm"

datanode_temp=()
IFS=',' read -ra datanodes <<< "$datanode_dir"
for datanode in "${datanodes[@]}"
do
        name_fetch_check "$datanode" "datanode" "dir"
        datanode_temp+=("$curr_unm")
done
join_by(){ local IFS="$1"; shift; echo "${datanode_temp[*]}"; }
datanode_dir_final="$(join_by ,)"

name_fetch_check "$hadoop_temp_dir" "Hadoop temp" "dir"
hadoop_temp_dir_final="$curr_unm"

name_fetch_check "$install_dir" "Hadoop installation" "dir"
install_dir_final="$curr_unm"

## ------------------------------------------------------ Validate Master and slaves access ------------------------------------------------------

echo "-------------------------------"
if [[ (${#master_final[@]} -eq ${#master_user_final[@]}) && (${#master_final[@]} -eq ${#master_access_typ_final[@]}) && (${#master_final[@]} -eq ${#master_access_tkn_final[@]}) ]]; then
	echo "Master server details - $(tput setaf 2) Sufficient $(tput sgr0)"
else
	echo "Master servers details - $(tput setaf 1) Insufficient / Extra entry $(tput sgr0)"
	echo "Please correct your entries"
	exit_f
fi

if [[ (${#slaves_final[@]} -eq ${#slaves_user_final[@]}) && (${#slaves_final[@]} -eq ${#slaves_acc_typ_final[@]}) && (${#slaves_final[@]} -eq ${#slaves_acc_tkn_final[@]}) ]]; then
	echo "Slave servers details - $(tput setaf 2) Sufficient $(tput sgr0)"
else
	echo "Slave servers details - $(tput setaf 1) Insufficient / Extra entry $(tput sgr0)"
	echo "Please correct your entries"
	exit_f
fi

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with servers"
echo "Master Server--------"
# validate_servers "${master_final[@]}" "${master_user_final[@]}" "${master_access_typ_final[@]}" "${master_access_tkn_final[@]}"
count=-1
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'" 
for srvr in ${master_final[@]}
do
	echo "Server '$((count+=1))' :: $(tput setaf 3) '${master_final[$count]}' - ${master_user_final[$count]} - ${master_access_typ_final[$count]} - ${master_access_tkn_final[$count]} $(tput sgr0)"
	conn_check "${master_final[$count]}" "${master_user_final[$count]}" "${master_access_typ_final[$count]}" "${master_access_tkn_final[$count]}"	
done

echo "Slave Servers--------" 
# validate_servers "${slaves_final[@]}" "${slaves_user_final[@]}" "${slaves_acc_typ_final[@]}" "${slaves_acc_tkn_final[@]}"
count=-1
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'" 
for srvr in ${slaves_final[@]}
do
	echo "Server '$((count+=1))' :: $(tput setaf 3) '${slaves_final[$count]}' - ${slaves_user_final[$count]} - ${slaves_acc_typ_final[$count]} - ${slaves_acc_tkn_final[$count]} $(tput sgr0)"
	conn_check "${slaves_final[$count]}" "${slaves_user_final[$count]}" "${slaves_acc_typ_final[$count]}" "${slaves_acc_tkn_final[$count]}"
done

## Concat server details
# servers_ips=("${master_final[@]}" "${slaves_final[@]}")
# servers_users=("${master_user_final[@]}" "${slaves_user_final[@]}")
# servers_acc_typ=("${master_access_typ_final[@]}" "${slaves_acc_typ_final[@]}")
# servers_acc_tkn=("${master_access_tkn_final[@]}" "${slaves_acc_tkn_final[@]}")
# echo "${servers_ips[@]}"
# echo "${servers_users[@]}"
# echo "${servers_acc_typ[@]}"
# echo "${servers_acc_tkn[@]}"

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

## ------------------------------------------------------ Establish connection between servers ------------------------------------------------------

echo "-------------------------------"
echo "Creating password-less 'ssh' between Master and slaves"
conn_est "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"

## ------------------------------------------------------ Push and install Hadoop in all servers  ------------------------------------------------------

# update sbin/install_hadoop.sh with install_dir
set -e
sed -i "s|INSTALL_DIRECTORY=.*|INSTALL_DIRECTORY=$install_dir_final|g" ../sbin/install_hadoop.sh
set +e

echo "-------------------------------"
echo "Hadoop Installation - Master"
install_hadoop "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"

echo "Hadoop Installation - Slaves"
count=-1
for srvr in ${slaves_final[@]}
do
	count="$((count+=1))"
	install_hadoop "${slaves_final[$count]}" "${slaves_user_final[$count]}" "${slaves_acc_typ_final[$count]}" "${slaves_acc_tkn_final[$count]}"
done

## ------------------------------------------------------ Generate Hadoop configuration  ------------------------------------------------------

echo "-------------------------------"
echo "Generating Hadoop configuration"
if [[ ! -z "$(ls -A ../conf/hadoop/generated_hadoop_config/)" ]]; then
	echo "Clearing pre-generated hadoop configuration"
	rm ../conf/hadoop/generated_hadoop_config/*
fi

cp ../conf/hadoop/config_template/core-site.xml ../conf/hadoop/generated_hadoop_config/
sed -i "s@#HADOOP_MASTER_IP#@$master_final@" ../conf/hadoop/generated_hadoop_config/core-site.xml
sed -i "s@#HADOOP_TEMP_DIR#@$hadoop_temp_dir_final@" ../conf/hadoop/generated_hadoop_config/core-site.xml

cp ../conf/hadoop/config_template/hdfs-site.xml ../conf/hadoop/generated_hadoop_config/
sed -i "s@#NAMENODE_DIR#@$namenode_dir_final@" ../conf/hadoop/generated_hadoop_config/hdfs-site.xml
sed -i "s@#DATANODE_DIR#@$datanode_dir_final@" ../conf/hadoop/generated_hadoop_config/hdfs-site.xml

cp ../conf/hadoop/config_template/mapred-site.xml ../conf/hadoop/generated_hadoop_config/
cp ../conf/hadoop/config_template/fairScheduler.xml ../conf/hadoop/generated_hadoop_config/

cp ../conf/hadoop/config_template/yarn-site.xml ../conf/hadoop/generated_hadoop_config/
sed -i "s@#HADOOP_MASTER_IP#@$master_final@" ../conf/hadoop/generated_hadoop_config/yarn-site.xml

datanodes_join_by(){
	IFS=',' read -ra datanodes_temp <<< "$1"
	datanodes_temp=("${datanodes_temp[@]/%/$3}")
	inner_join_by(){ local IFS="$1"; shift; echo "${datanodes_temp[*]}"; }
	local datanode_temp_final="$(inner_join_by $2)"
	echo "$datanode_temp_final"
}
datanode_dir_local=$(datanodes_join_by "$datanode_dir_final" "," "/yarn/local")
datanode_dir_logs=$(datanodes_join_by "$datanode_dir_final" "," "/yarn/logs")
datanode_dir_app_logs=$(datanodes_join_by "$datanode_dir_final" "," "/yarn/app-logs")
sed -i "s@#DATANODE_DIR_LOCAL#@$datanode_dir_local@" ../conf/hadoop/generated_hadoop_config/yarn-site.xml
sed -i "s@#DATANODE_DIR_LOGS#@$datanode_dir_logs@" ../conf/hadoop/generated_hadoop_config/yarn-site.xml
sed -i "s@#DATANODE_DIR_APP_LOGS#@$datanode_dir_app_logs@" ../conf/hadoop/generated_hadoop_config/yarn-site.xml
sed -i "s@#INSTALL_DIRECTORY#@$install_dir_final/tdss@" ../conf/hadoop/generated_hadoop_config/yarn-site.xml

# master
echo "$master_final" >> ../conf/hadoop/generated_hadoop_config/masters

# slaves
for slv in ${slaves_final[@]}
do
	echo "$slv" >> ../conf/hadoop/generated_hadoop_config/slaves
done
echo "Generating Hadoop configuration -$(tput setaf 2) Done $(tput sgr0)"


## ------------------------------------------------------ Configure Hadoop in all servers  ------------------------------------------------------

echo "-------------------------------"
echo "Updating Hadoop Configuration - Master"
update_hadoop_conf "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"

echo "Hadoop Installation - Slaves"
count=-1
for srvr in ${slaves_final[@]}
do
	count="$((count+=1))"
	update_hadoop_conf "${slaves_final[$count]}" "${slaves_user_final[$count]}" "${slaves_acc_typ_final[$count]}" "${slaves_acc_tkn_final[$count]}"
done
echo "Updating Hadoop Configuration in all servers -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Format Hadoop NameNode   ------------------------------------------------------

echo "-------------------------------"
echo "Fomrating Hadoop NameNode"

# echo "-------------------------------"
# while true 
# do
#     read -p "Format Hadoop namenode .. :: (y/n)?" choice
#     case "$choice" in
#       y|Y ) echo "$(tput setaf 2)Installation resumed$(tput sgr0)"; break;;
#       n|N ) exit_s;;
#       * ) echo "Invalid entry"; continue;;
#     esac
# done

namenode_format "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
echo "Fomrating Hadoop NameNode -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Start Hadoop  ------------------------------------------------------

# echo "-------------------------------"
# while true 
# do
#     read -p "Start Hadoop.. :: (y/n)?" choice
#     case "$choice" in
#       y|Y ) echo "$(tput setaf 2)Installation resumed$(tput sgr0)"; break;;
#       n|N ) exit_s;;
#       * ) echo "Invalid entry"; continue;;
#     esac
# done

echo "-------------------------------"
# echo "Starting Hadoop"
# start_hadoop "$master_final" "$master_user_final" "$master_access_typ_final" "$master_access_tkn_final"
# echo "Starting Hadoop -$(tput setaf 2) Done $(tput sgr0)"
cd ../sbin
sh hadoop-remote-start-all.sh
cd $curr_dir

## ------------------------------------------------------ Push Spark jars to HDFS  ------------------------------------------------------

# echo "-------------------------------"
# while true 
# do
#     read -p "Push Spark jars to HDFS .. :: (y/n)?" choice
#     case "$choice" in
#       y|Y ) echo "$(tput setaf 2)Installation resumed$(tput sgr0)"; break;;
#       n|N ) exit_s;;
#       * ) echo "Invalid entry"; continue;;
#     esac
# done

echo "-------------------------------"
echo "Pushing Spark jars to HDFS"
sleep 10
cd ../sbin
sh hadoop-remote-push-jars.sh
cd $curr_dir
echo "Pushing Spark jars to HDFS -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Hadoop start and stop  ------------------------------------------------------
exit_s

