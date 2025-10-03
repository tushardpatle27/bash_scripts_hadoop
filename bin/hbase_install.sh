#!/bin/bash
source=../conf/config.yaml > /dev/null 2>&1 
install_dir=../libs
#INSTALL_DIRECTORY=/home/ec2-user/
#set -e
conn_web(){

        if [[ "$TOMCAT_AUTH_MECH"=="KEY" ]];then
                ssh -i "$TOMCAT_SERVER_KEY_LOCATION" "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH"=="PASS" ]]; then
                sshpass -p "$TOMCAT_SERVER_PASSWORD" "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH"=="NIL" ]]; then
                ssh "$TOMCAT_SERVER_USERNAME"@"$t" $*
        else
                echo "unexpected token type"; exit;
        fi
}
conn_web2(){
         if [[ "$TOMCAT_AUTH_MECH"=="KEY" ]];then
                scp -i "$TOMCAT_SERVER_KEY_LOCATION" $*
        elif [[ "$TOMCAT_AUTH_MECH"=="PASS" ]]; then
                sshpass -p "$TOMCAT_SERVER_PASSWORD" scp $*
        elif [[ "$TOMCAT_AUTH_MECH"=="NIL" ]]; then
                scp $*
        else
                echo "unexpected token type"; exit;
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

INSTALL_DIRECTORY=$(cat "$source" | grep ^INSTALL_DIRECTORY | cut -d ":" -f 2 | sed 's/ //')
TOMCAT_SERVER_USERNAME=$(cat "$source" | grep ^TOMCAT_SERVER_USERNAME | cut -d ":" -f 2 | sed 's/ //')
TOMCAT_SERVER_KEY_LOCATION=$(cat "$source" | grep ^TOMCAT_SERVER_KEY_LOCATION | cut -d ":" -f 2 | sed 's/ //')
HBASE_MASTER_IP=$(cat "$source" | grep ^HBASE_MASTER_IP | cut -d ":" -f 2 | sed 's/ //')
HBASE_REGION_IP=$(cat "$source" | grep ^HBASE_REGION_IP | cut -d ":" -f 2 | sed 's/ //')
HBASE_BACKUP_MASTER=$(cat "$source" | grep ^HBASE_BACKUP_MASTERS | cut -d ":" -f 2 | sed 's/ //')


# clear bashrc
sed -i '/HBASE/d' ~/.bashrc
sed -i '/PHOENIX/d' ~/.bashrc



cd ../sbin
sh hbase_config.sh >> ../logs/hbase/hbase.log
cd ../bin
echo $HBASE_MASTER_IP
IFS="," read -ra servers <<< "$HBASE_MASTER_IP"
for t in "${servers[@]}"
do
echo "$t"
echo "Installing HBASE in Master"
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/hbase > /dev/null 2&>1
conn_web2 "$install_dir"/hbase-2.4.14-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14 "$INSTALL_DIRECTORY"/tdss/hbase
conn_web2 "$install_dir"/phoenix-hbase-2.4-5.1.2-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/phoenix > /dev/null 2&>1
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin "$INSTALL_DIRECTORY"/tdss/phoenix
conn_web cp "$INSTALL_DIRECTORY"/tdss/phoenix/phoenix-server-hbase-2.4-5.1.2.jar "$INSTALL_DIRECTORY"/tdss/hbase/lib/
#conn_web cp "$INSTALL_DIRECTORY"/tdss/hbase/conf/hbase-site.xml "$INSTALL_DIRECTORY"/tdss/phoenix/bin/
#cp ../conf/hbase/config_template/master/hbase-site.xml ../conf/hbase/generated_hbase_config/master/
conn_web2 ../conf/hbase/generated_hbase_config/master/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/phoenix/bin/
conn_web2 ../conf/hbase/generated_hbase_config/master/backup-masters "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/regionservers "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/hbase-env.sh "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
echo "export HBASE_HOME="$INSTALL_DIRECTORY"/tdss/hbase/" | conn_web "cat >> ~/.bashrc"
done

echo $HBASE_BACKUP_MASTER
IFS="," read -ra servers <<< "$HBASE_BACKUP_MASTER"
for t in "${servers[@]}"
do
echo "$t"
echo "Installing HBASE in Backup Master"
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/hbase > /dev/null 2&>1
conn_web2 "$install_dir"/hbase-2.4.14-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14 "$INSTALL_DIRECTORY"/tdss/hbase
conn_web2 "$install_dir"/phoenix-hbase-2.4-5.1.2-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/phoenix > /dev/null 2&>1
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin "$INSTALL_DIRECTORY"/tdss/phoenix
conn_web cp "$INSTALL_DIRECTORY"/tdss/phoenix/phoenix-server-hbase-2.4-5.1.2.jar "$INSTALL_DIRECTORY"/tdss/hbase/lib/
#conn_web cp "$INSTALL_DIRECTORY"/tdss/hbase/conf/hbase-site.xml "$INSTALL_DIRECTORY"/tdss/phoenix/bin/
#cp ../conf/hbase/config_template/master/hbase-site.xml ../conf/hbase/generated_hbase_config/master/
conn_web2 ../conf/hbase/generated_hbase_config/master/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/phoenix/bin/
conn_web2 ../conf/hbase/generated_hbase_config/master/backup-masters "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/regionservers "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/hbase-env.sh "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
echo "export HBASE_HOME="$INSTALL_DIRECTORY"/tdss/hbase/" | conn_web "cat >> ~/.bashrc"
done


echo $HBASE_REGION_IP
IFS="," read -ra server <<< "$HBASE_REGION_IP"
for t in "${server[@]}"
do
echo "Installing HBASE in Slaves"

conn_web rm -r "$INSTALL_DIRECTORY"/tdss/hbase > /dev/null 2&>1
conn_web2 "$install_dir"/hbase-2.4.14-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/hbase-2.4.14 "$INSTALL_DIRECTORY"/tdss/hbase
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/phoenix
conn_web2 "$install_dir"/phoenix-hbase-2.4-5.1.2-bin.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin.tar.gz -C "$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/phoenix-hbase-2.4-5.1.2-bin "$INSTALL_DIRECTORY"/tdss/phoenix
conn_web cp "$INSTALL_DIRECTORY"/tdss/phoenix/phoenix-server-hbase-2.4-5.1.2.jar "$INSTALL_DIRECTORY"/tdss/hbase/lib/
#conn_web cp "$INSTALL_DIRECTORY"/tdss/hbase/conf/hbase-site.xml "$INSTALL_DIRECTORY"/tdss/phoenix/bin/
#cp ../conf/hbase/config_template/slave/hbase-site.xml ../conf/hbase/generated_hbase_config/slave/
conn_web2 ../conf/hbase/generated_hbase_config/slave/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/slave/regionservers "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/backup-masters "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/hbase-env.sh "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/hbase/conf/
conn_web2 ../conf/hbase/generated_hbase_config/master/hbase-site.xml "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/phoenix/bin/
#conn_web cp "$INSTALL_DIRECTORY"/tdss/hbase/conf/hbase-site.xml "$INSTALL_DIRECTORY"/tdss/phoenix/bin/
echo "export HBASE_HOME="$INSTALL_DIRECTORY"/tdss/hbase/" | conn_web "cat >> ~/.bashrc"
echo "export PATH=\$PATH:\$HBASE_HOME/bin:\$PATH" >> ~/.bashrc
done

echo "Starting Hbase Service"
#IFS="," read -ra servers <<< "$HBASE_REGION_IP"
#for t in "${servers[@]}"
#do
#  echo "STARTING HBASE"
  #conn_web "$INSTALL_DIRECTORY"/tdss/hbase/bin/start-hbase.sh
  source ~/.bashrc
  cd $HBASE_HOME
 ./bin/start-hbase.sh
 cd $HOME
#done
