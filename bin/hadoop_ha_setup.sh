#!/bin/bash

echo "############################### -- TDSS :: Hadoop Setup"
curr_dir=$(pwd)
config_file_path=../conf/config.yaml

# To terminate
exit_f(){
	echo "$(tput setaf 1)Aborting...$(tput sgr0)";
    	echo "############################### -- TDSS :: Hadoop Setup -- $(tput setaf 1)Failed$(tput sgr0)"
    	exit 1;
}
exit_s(){
	echo "-------------------------------"
	echo "Use the following scripts which are under 'sbin' dir to start and stop Hadoop"
	echo "To Start -$(tput setaf 2) hadoop-remote-start.sh $(tput sgr0)"
	echo "To Stop -$(tput setaf 2) hadoop-remote-stop.sh $(tput sgr0)"

	echo "Use the following script which is under 'sbin' dir to push Sprark libs to HDFS"
	echo "To push jars -$(tput setaf 2) hadoop-remote-push-jars.sh $(tput sgr0)"

	echo "############################### -- TDSS :: Hadoop Setup -- $(tput setaf 2)Completed$(tput sgr0)"
	exit;
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

	# generate rsa and get public key
	rm -f ../temp/temp_ssh_key

	IFS=',' read -ra servers_temp <<< "$1"
	for server in "${servers_temp[@]}" 
	do
		# generate rsa
		set -e
		echo "Generating ssh key in '$server'"
		if [[ "$3" == "NIL" ]]; then
			ssh "$2@$server" 'bash -s' < ../sbin/generate_ssh.sh
			mkey=$(ssh "$2@$server" 'bash -s' < ../sbin/get_ssh.sh)
		elif [[ "$3" == "KEY" ]]; then
			ssh -i "$4" "$2@$server" 'bash -s' < ../sbin/generate_ssh.sh
			mkey=$(ssh -i "$4" "$2@$server" 'bash -s' < ../sbin/get_ssh.sh)
		elif [[ "$3" == "PASS" ]]; then
			sshpass -p "$4" ssh "$2@$server" 'bash -s' < ../sbin/generate_ssh.sh
			mkey=$(sshpass -p "$4" ssh "$2@$server" 'bash -s' < ../sbin/get_ssh.sh)
		else
			echo "unexpected token type"; exit_f;
		fi
		set +e

		# get public key
		echo "Getting public key from '$server'"
		echo "$mkey" >> ../temp/temp_ssh_key
	done

	# Copy all servers public keys to all servers
	IFS=',' read -ra servers_temp <<< "$1"
	for server in "${servers_temp[@]}" 
	do
		# generate rsa
		set -e
		echo "Putting all servers public keys to '$server'"
		if [[ "$3" == "NIL" ]]; then
			scp ../temp/temp_ssh_key "$2@$server:~/master_ssh_key"
			ssh "$2@$server" 'bash -s' < ../sbin/put_ssh.sh
		elif [[ "$3" == "KEY" ]]; then
			scp -i "$4" ../temp/temp_ssh_key "$2@$server:~/master_ssh_key"
			ssh -i "$4" "$2@$server" 'bash -s' < ../sbin/put_ssh.sh
		elif [[ "$3" == "PASS" ]]; then
			sshpass -p "$4" scp ../temp/temp_ssh_key "$2@$server:~/master_ssh_key"
			sshpass -p "$4" ssh "$2@$server" 'bash -s' < ../sbin/put_ssh.sh
		else
			echo "unexpected token type"; exit_f;
		fi
		set +e
	done
	echo "$(tput setaf 2)Password-less connection established$(tput sgr0)"
}

# Install Hadoop
install_hadoop(){
	set -e
	echo "$(tput setaf 3)Installing Hadoop in '$1'$(tput sgr0)"
	if [[ $3 == 'NIL' ]]; then
		scp ../libs/hadoop*.tar.gz "$2@$1:~/"
		scp ../conf/config.yaml "$2@$1:~/tdss/"
		ssh "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../libs/hadoop*.tar.gz "$2@$1:~/"
		scp -i "$4" ../conf/config.yaml "$2@$1:~/tdss/"
		ssh -i "$4" "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../libs/hadoop*.tar.gz "$2@$1:~/"
		sshpass -p "$4" scp ../conf/config.yaml "$2@$1:~/tdss/"
		sshpass -p "$4" ssh "$2@$1" 'bash -s' < ../sbin/install_hadoop.sh
	fi
	set +e
}

# Update Hadoop config
update_hadoop_conf(){
	echo "Updating hadoop configuration in $(tput setaf 3)'$1'$(tput sgr0)"
	if [[ $3 == 'NIL' ]]; then
		scp ../conf/hadoop/ha_generated_hadoop_config/* "$2@$1:$install_directory_final/tdss/hadoop/etc/hadoop/"
	elif [[ $3 == 'KEY' ]]; then
		scp -i "$4" ../conf/hadoop/ha_generated_hadoop_config/* "$2@$1:$install_directory_final/tdss/hadoop/etc/hadoop/"
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" scp ../conf/hadoop/ha_generated_hadoop_config/* "$2@$1:$install_directory_final/tdss/hadoop/etc/hadoop/"
	fi
}

# Run Command in remote machine
run_cmd(){
	echo "$6 $(tput setaf 3)'$1'$(tput sgr0)"
	if [[ $3 == 'NIL' ]]; then
		ssh "$2@$1" $5
	elif [[ $3 == 'KEY' ]]; then
		ssh -i "$4" "$2@$1" $5
	elif [[ $3 == 'PASS' ]]; then
		sshpass -p "$4" ssh "$2@$1" $5
	fi
}

## ------------------------------------------------------ Get server details ------------------------------------------------------

echo "-------------------------------"
echo "Fetching details .."
install_directory=$(cat "$config_file_path" | grep ^INSTALL_DIRECTORY | cut -d ":" -f 2 | sed 's/ //')

hadoop_cluster_name=$(cat "$config_file_path" | grep ^HADOOP_CLUSTER_NAME | cut -d ":" -f 2)

hadoop_ha_master_servers=$(cat "$config_file_path" | grep ^HADOOP_HA_MASTER_SERVERS | cut -d ":" -f 2)
hadoop_workers_servers=$(cat "$config_file_path" | grep ^HADOOP_WORKERS_SERVERS | cut -d ":" -f 2)
hadoop_master_server=$(cat "$config_file_path" | grep ^HADOOP_MASTER_SERVER | cut -d ":" -f 2)
hadoop_edge_server=$(cat "$config_file_path" | grep ^HADOOP_EDGE_SERVER | cut -d ":" -f 2)

hadoop_server_username=$(cat "$config_file_path" | grep ^HADOOP_SERVER_USERNAME | cut -d ":" -f 2)
hadoop_server_auth_mech=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_MECH | cut -d ":" -f 2)
hadoop_server_auth_tkn=$(cat "$config_file_path" | grep ^HADOOP_SERVER_AUTH_TKN | cut -d ":" -f 2)

hadoop_meta_dir=$(cat "$config_file_path" | grep ^HADOOP_META_DIR | cut -d ":" -f 2)
hadoop_data_dir=$(cat "$config_file_path" | grep ^HADOOP_DATA_DIR | cut -d ":" -f 2)
hadoop_temp_dir=$(cat "$config_file_path" | grep ^HADOOP_TEMP_DIR | cut -d ":" -f 2)
hadoop_jn_e_dir=$(cat "$config_file_path" | grep ^HADOOP_JN_E_DIR | cut -d ":" -f 2)


#  hadoop_cluster_name string validation
name_fetch_check "$hadoop_cluster_name" "Hadoop" "cluster-name"
hadoop_cluster_name_final="$curr_unm"

# hadoop_ha_master_servers ip validation
hadoop_ha_master_servers_final=()
IFS=',' read -ra servers_temp <<< "$hadoop_ha_master_servers"
for server in "${servers_temp[@]}" 
do
 	name_fetch_check "$server" "Hadoop Master" "IP"
 	hadoop_ha_master_servers_final+=("$curr_unm")
done



# hadoop_slave_servers ip validation
hadoop_workers_servers_final=()
IFS=',' read -ra servers_temp <<< "$hadoop_workers_servers"
for server in "${servers_temp[@]}" 
do
 	name_fetch_check "$server" "Hadoop workers" "IP"
 	hadoop_workers_servers_final+=("$curr_unm")
done

# hadoop_edge_server ip validation
hadoop_edge_server_final=()
IFS=',' read -ra servers_temp <<< "$hadoop_edge_server"
for server in "${servers_temp[@]}"
do
	name_fetch_check "$server" "Hadoop edge" "IP"
	hadoop_edge_server_final+=("$curr_unm")
done


#  hadoop_master_server string validation
name_fetch_check "$hadoop_master_server" "Hadoop" "master-server"
hadoop_master_server_final="$curr_unm"

#  hadoop_server_username string validation
name_fetch_check "$hadoop_server_username" "Hadoop servers'" "username"
hadoop_server_username_final="$curr_unm"


#  hadoop_server_auth_mech string validation
name_fetch_check "$hadoop_server_auth_mech" "Hadoop servers'" "access-type"
hadoop_server_auth_mech_final="$curr_unm"

#  hadoop_server_auth_tkn string validation
name_fetch_check "$hadoop_server_auth_tkn" "Hadoop servers'" "access-token"
hadoop_server_auth_tkn_final="$curr_unm"


#  hadoop_meta_dir string validation
name_fetch_check "$hadoop_meta_dir" "Hadoop" "meta-dir"
hadoop_meta_dir_final="$curr_unm"

#  hadoop_data_dir string validation
hadoop_data_dir_temp=()
IFS=',' read -ra array <<< "$hadoop_data_dir"
for element in "${array[@]}"
do
    name_fetch_check "$element" "Hadoop" "data-dir"
    hadoop_data_dir_temp+=("$curr_unm")
done
join_by(){ local IFS="$1"; shift; echo "${hadoop_data_dir_temp[*]}"; }
hadoop_data_dir_final="$(join_by ,)"

#  hadoop_temp_dir string validation
name_fetch_check "$hadoop_temp_dir" "Hadoop" "temp-dir"
hadoop_temp_dir_final="$curr_unm"

#  install_directory string validation
name_fetch_check "$install_directory" "Hadoop" "installation-dir"
install_directory_final="$curr_unm"

#  hadoop_jn_e_dir string validation
name_fetch_check "$hadoop_jn_e_dir" "Hadoop" "journalnode-edits-dir"
hadoop_jn_e_dir_final="$curr_unm"

## ------------------------------------------------------ Checking connectivity with servers ------------------------------------------------------

echo "-------------------------------"
echo "Checking connectivity with servers"

echo "Master Servers -------"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
count=-1 
for server in ${hadoop_ha_master_servers_final[@]}
do
	count=$((count+=1))
	echo "Server Details :: $(tput setaf 3) '$server' - $hadoop_server_username_final - $hadoop_server_auth_mech_final - $hadoop_server_auth_tkn_final $(tput sgr0)"
	conn_check "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"
done

echo "Workers Servers --------" 
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
count=-1 
for server in ${hadoop_workers_servers_final[@]}
do
	count=$((count+=1))
	echo "Server Details :: $(tput setaf 3) '$server' - $hadoop_server_username_final - $hadoop_server_auth_mech_final - $hadoop_server_auth_tkn_final $(tput sgr0)"
	conn_check "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"
done


echo "Edge Server --------"
echo "Server Details :: 'IP' - 'Username' - 'Access Token Type' - 'Access Token'"
count=-1
for server in ${hadoop_edge_server_final[@]}
do
        count=$((count+=1))
        echo "Server Details :: $(tput setaf 3) '$server' - $hadoop_server_username_final - $hadoop_server_auth_mech_final - $hadoop_server_auth_tkn_final $(tput sgr0)"
        conn_check "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"
done


## ------------------------------------------------------ List of all servers (unique) ------------------------------------------------------

# draw unique servers
all_servers=("${hadoop_ha_master_servers_final[@]}" "${hadoop_workers_servers_final[@]}" "${hadoop_edge_server_final[@]}")
all_servers_final=($(echo "${all_servers[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# array to string (servers)
join_by(){ local IFS="$1"; shift; echo "${all_servers_final[*]}"; }
all_servers_final_as_string="$(join_by ,)"

## ------------------------------------------------------ Establish connection between servers ------------------------------------------------------
echo "-------------------------------"
echo "Creating password-less 'ssh' between $(tput setaf 3)'${all_servers_final[@]}'$(tput sgr0)"
conn_est "$all_servers_final_as_string" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"

## ------------------------------------------------------ Push and install Hadoop in all servers  ------------------------------------------------------

# update sbin/install_hadoop.sh with install_dir
set -e
sed -i "s|INSTALL_DIRECTORY=.*|INSTALL_DIRECTORY=$install_directory_final|g" ../sbin/install_hadoop.sh
set +e

echo "-------------------------------"
echo "Hadoop Deployment"
for server in ${all_servers_final[@]}
do
	install_hadoop "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"
done
echo "Hadoop Deployment - $(tput setaf 2)Done$(tput sgr0)"

## ------------------------------------------------------ Generate Hadoop configuration  ------------------------------------------------------

echo "-------------------------------"
echo "Generating Hadoop configuration"

# clear pre-generated hadoop configuration
if [[ ! -z "$(ls -A ../conf/hadoop/ha_generated_hadoop_config/)" ]]; then
	echo "Clearing pre-generated hadoop configuration"
	rm ../conf/hadoop/ha_generated_hadoop_config/*
fi

# zk quorum and qjournal
zookeeper_quorum=
zookeeper_qjournal=
for server in ${hadoop_ha_master_servers_final[@]}
do
	zookeeper_quorum+="$server:2181,"
	zookeeper_qjournal+="$server:8485;"
done
zookeeper_quorum_final="${zookeeper_quorum%,}"
zookeeper_qjournal_final="${zookeeper_qjournal%;}"

# logical NNs and RMs configuration
nn=
rm=
nn_rpc_address=()
nn_http_address=()
rm_hostname=()
rm_address=()
rm_webapp_address=()

count=0 
for server in ${hadoop_ha_master_servers_final[@]}
do
	count=$((count+=1))

	nn+="nn$count,"
	
	read -r -d '' nn_rpc_address_temp <<- EOM
		<property>
		<name>dfs.namenode.rpc-address.$hadoop_cluster_name_final.nn$count</name>
		<value>$server:9000</value>
		</property>
	EOM
	nn_rpc_address+=("$nn_rpc_address_temp")

	read -r -d '' nn_http_address_temp <<- EOM
		<property>
		<name>dfs.namenode.http-address.$hadoop_cluster_name_final.nn$count</name>
		<value>$server:9870</value>
		</property>
	EOM
	nn_http_address+=("$nn_http_address_temp")

	rm+="rm$count,"

	read -r -d '' rm_hostname_temp <<- EOM
		<property>
		<name>yarn.resourcemanager.hostname.rm$count</name>
		<value>$server</value>
		</property>
	EOM
	rm_hostname+=("$rm_hostname_temp")

	read -r -d '' rm_address_temp <<- EOM
		<property>
		<name>yarn.resourcemanager.address.rm$count</name>
		<value>$server:8032</value>
		</property>
	EOM
	rm_address+=("$rm_address_temp")

	read -r -d '' rm_webapp_address_temp <<- EOM
		<property>
		<name>yarn.resourcemanager.webapp.address.rm$count</name>
		<value>$server:8088</value>
		</property>
	EOM
	rm_webapp_address+=("$rm_webapp_address_temp")

	# patch work (non FNN)
	if [[ "$count" == 2 ]]; then break; fi

done

nn_final="${nn%,}"
nn_rpc_address_final=$(IFS=$'\n'; echo "${nn_rpc_address[*]}")
nn_http_address_final=$(IFS=$'\n'; echo "${nn_http_address[*]}")
rm_final="${rm%,}"
rm_hostname_final=$(IFS=$'\n'; echo "${rm_hostname[*]}")
rm_address_final=$(IFS=$'\n'; echo "${rm_address[*]}")
rm_webapp_address_final=$(IFS=$'\n'; echo "${rm_webapp_address[*]}")


# core-site.xml
echo "Generating - core-site.xml"
cp ../conf/hadoop/ha_config_template/core-site.xml ../conf/hadoop/ha_generated_hadoop_config/
sed -i "s@#HADOOP_CLUSTER_NAME#@$hadoop_cluster_name_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml
sed -i "s@#HADOOP_TEMP_DIR#@$hadoop_temp_dir_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml
#sed -i "s@#HADOOP_JN_E_DIR#@$hadoop_jn_e_dir_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml
sed -i "s@#HADOOP_NN_SHARED_EDITS#@$zookeeper_qjournal_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml
sed -i "s@#ZOOKEEPER_SERVERS#@$zookeeper_quorum_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml

# hdfs-site.xml
echo "Generating - hdfs-site.xml"
cp ../conf/hadoop/ha_config_template/hdfs-site.xml ../conf/hadoop/ha_generated_hadoop_config/
sed -i "s@#NAMENODE_DIR#@$hadoop_meta_dir_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
sed -i "s@#DATANODE_DIR#@$hadoop_data_dir_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
sed -i "s@#HADOOP_CLUSTER_NAME#@$hadoop_cluster_name_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
sed -i "s@#HADOOP_ALL_NAMENODES#@$nn_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
echo "${nn_rpc_address_final}" > ../temp/nn_rpc.conf
sed -i -e '/#HADOOP_NN_RPC_ADDRESS#/r ../temp/nn_rpc.conf' -e "//d" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
echo "${nn_http_address_final}" > ../temp/nn_http.conf
sed -i -e '/#HADOOP_NN_HTTP_ADDRESS#/r ../temp/nn_http.conf' -e "//d" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
sed -i "s@#ZOOKEEPER_SERVERS#@$zookeeper_quorum_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml
#sed -i "s@#HADOOP_NN_SHARED_EDITS#@$zookeeper_qjournal_final@" ../conf/hadoop/ha_generated_hadoop_config/core-site.xml
sed -i "s@#HADOOP_JN_E_DIR#@$hadoop_jn_e_dir_final@" ../conf/hadoop/ha_generated_hadoop_config/hdfs-site.xml

# mapred-site.xml
echo "Generating - mapred-site.xml"
cp ../conf/hadoop/ha_config_template/mapred-site.xml ../conf/hadoop/ha_generated_hadoop_config/
sed -i "s@#HADOOP_MASTER_SERVER#@$hadoop_master_server_final@" ../conf/hadoop/ha_generated_hadoop_config/mapred-site.xml

# hadoop-env.sh
echo "Generating - hadoop-env.sh"
cp ../conf/hadoop/ha_config_template/hadoop-env.sh ../conf/hadoop/ha_generated_hadoop_config/

# yarn-env.sh
echo "Generating - yarn-env.sh"
cp ../conf/hadoop/ha_config_template/yarn-env.sh ../conf/hadoop/ha_generated_hadoop_config/


# fairScheduler.xml
echo "Generating - fairScheduler.xml"
cp ../conf/hadoop/ha_config_template/fairScheduler.xml ../conf/hadoop/ha_generated_hadoop_config/

# yarn-site.xml
echo "Generating - yarn-site.xml"
cp ../conf/hadoop/ha_config_template/yarn-site.xml ../conf/hadoop/ha_generated_hadoop_config/
sed -i "s@#HADOOP_CLUSTER_NAME#@$hadoop_cluster_name_final@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#HADOOP_ALL_RM#@$rm_final@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
echo "${rm_hostname_final}" > ../temp/rm_hostname.conf
sed -i -e '/#RM_HOSTNAME#/r ../temp/rm_hostname.conf' -e "//d" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
echo "${rm_address_final}" > ../temp/rm_address.conf
sed -i -e '/#RM_ADDRESS#/r ../temp/rm_address.conf' -e "//d" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
echo "${rm_webapp_address_final}" > ../temp/rm_webapp_address.conf
sed -i -e '/#RM_WEBAPP_ADDRESS#/r ../temp/rm_webapp_address.conf' -e "//d" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#ZOOKEEPER_SERVERS#@$zookeeper_quorum_final@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml

datanodes_join_by(){
	IFS=',' read -ra datanodes_temp <<< "$1"
	datanodes_temp=("${datanodes_temp[@]/%/$3}")
	inner_join_by(){ local IFS="$1"; shift; echo "${datanodes_temp[*]}"; }
	local datanode_temp_final="$(inner_join_by $2)"
	echo "$datanode_temp_final"
}
datanode_dir_local=$(datanodes_join_by "$hadoop_data_dir_final" "," "/yarn/local")
datanode_dir_logs=$(datanodes_join_by "$hadoop_data_dir_final" "," "/yarn/logs")
datanode_dir_app_logs=$(datanodes_join_by "$hadoop_data_dir_final" "," "/yarn/app-logs")

sed -i "s@#DATANODE_DIR_LOCAL#@$datanode_dir_local@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#DATANODE_DIR_LOGS#@$datanode_dir_logs@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#DATANODE_DIR_APP_LOGS#@$datanode_dir_app_logs@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#INSTALL_DIRECTORY#@$install_directory_final/tdss@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml
sed -i "s@#HADOOP_MASTER_IP#@${hadoop_ha_master_servers_final[0]}@" ../conf/hadoop/ha_generated_hadoop_config/yarn-site.xml

# workers
echo "Generating - workers"
for server in ${hadoop_workers_servers_final[@]}
do
	echo "$server" >> ../conf/hadoop/ha_generated_hadoop_config/workers
done

echo "Generating Hadoop configuration -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Update Hadoop Configure in all nodes  ------------------------------------------------------

echo "-------------------------------"
echo "Updating Hadoop Configuration in all nodes"
for server in ${all_servers_final[@]}
do
	update_hadoop_conf "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final"
done
echo "Updating Hadoop Configuration in all nodes -$(tput setaf 2) Done $(tput sgr0)"

## ------------------------------------------------------ Setup Hadoop  ------------------------------------------------------

echo "-------------------------------"
echo "Setting up Hadoop"

# Start JNs
for server in ${hadoop_ha_master_servers_final[@]}
do
	run_cmd "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon start journalnode" "Starting JournalNode in"
done
# Format NN in nn1
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs namenode -format" "Formatting NameNode in"
# Start NN in nn1
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon  start namenode" "Starting NameNode in"
# bootstrapStandby NN in nn2
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs namenode -bootstrapStandby" "bootstrapStandby NameNode in"
# Start NN in nn2
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon start namenode" "Starting NameNode in"
#exit;
# Start Zookeeper Service
# cd ../sbin
# sh zookeeper-remote-start-quorum.sh
# cd ../bin

# Start DataNodes
for server in ${hadoop_slave_servers_final[@]}
do
	run_cmd "$server" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon start datanode" "Starting DataNodes in"
done

# Format ZK in nn2 (Considering  nn2 as 'leader')
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs zkfc -formatZK" "Formatting ZKFC in"
# Start ZKFC in nn2 
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon start zkfc" "Starting ZKFC in"
# Start ZKFC in nn1 
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs --daemon start zkfc" "Starting ZKFC in"

# Check HDFS Service State from nn2
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs haadmin -getAllServiceState" "Checking HDFS service state from"

# Stop All Hadoop Services from nn2
run_cmd "${hadoop_ha_master_servers_final[1]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "stop-all.sh" "Stopping all hadoop services from"
#  Start All Hadoop Services from nn1
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "start-all.sh" "Starting all hadoop services from"

# Check HDFS Service State from nn1
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "hdfs haadmin -getAllServiceState" "Checking HDFS service state from"
# Check YARN Service State from nn1
run_cmd "${hadoop_ha_master_servers_final[0]}" "$hadoop_server_username_final" "$hadoop_server_auth_mech_final" "$hadoop_server_auth_tkn_final" "yarn rmadmin -getAllServiceState" "Checking YARN service state from"
echo "Setting up Hadoop - $(tput setaf 2)Done$(tput sgr0)"
source ~/.bashrc
mapred --daemon start historyserver

## ------------------------------------------------------ Success  ------------------------------------------------------

exit_s
