#!/bin/bash

curr_dir=$(pwd)
config_file_path=../conf/config.yaml
client_config=/home/ec2-user/.my.cnf


hive_server_ip=`(cat "$config_file_path" | grep ^HIVE_METASTORE_SERVERS | cut -d ":" -f 2) |  sed 's/,/'\\\n'/g'`

#RDS_MYSQL_ENDPOINT="devopssanity210-server.cqyx9zsuwjgd.us-east-1.rds.amazonaws.com";
#RDS_MYSQL_USER="admin";
#RDS_MYSQL_PASS="Test123!!";
#RDS_MYSQL_BASE="your-database-name-goes here";
#SERVER_LIST=`cat /home/ec2-user/list.txt`

MYSQL_SERVER_IP=$(cat "$config_file_path" | grep ^DATABASE_SERVER_IP | cut -d ":" -f 2 | sed 's/ //') 
MYSQL_USER=$(cat "$config_file_path" | grep ^DATABASE_USERNAME | cut -d ":" -f 2 | sed 's/ //')
MYSQL_PASSWORD=$(cat "$config_file_path" | grep ^DATABASE_PASSWORD | cut -d ":" -f 2 | sed 's/ //')

sed -c -i "s/\(user *= *\).*/\1$MYSQL_USER/" $client_config
sed -c -i "s/\(password *= *\).*/\1$MYSQL_PASSWORD/" $client_config


for server_ip in $hive_server_ip
do
  ssh $server_ip 'sudo yum install -y mysql'
  ssh $server_ip 'mysql -h '$MYSQL_SERVER_IP' -e 'quit';'
  if [[ $? -eq 0 ]]; then
    echo "MySQL connection: OK";
  else
    echo "MySQL connection: Fail";
  fi;
done

