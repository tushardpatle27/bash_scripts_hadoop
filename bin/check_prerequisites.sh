source ../conf/config.yaml  > /dev/null 2>&1
install_dir=../libs
#set -e

conn_ssh(){

        if [[ "$JAVA_AUTH_MECH" == "KEY" ]];then
                ssh -i "$JAVA_SERVER_KEY_LOCATION"  "$JAVA_SERVERS_USERNAME"@"$j" $*
        elif [[ "$JAVA_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$JAVA_SERVER_PASSWORD" "$JAVA_SERVERS_USERNAME"@"$j" $*
        elif [[ "$JAVA_AUTH_MECH" == "NIL" ]]; then
                ssh "$JAVA_SERVERS_USERNAME"@"$j" $*
        else
                echo "unexpected token type"; exit;
        fi

}
conn_ssh2(){
         if [[ "$JAVA_AUTH_MECH" == "KEY" ]];then
                scp -i "$JAVA_SERVER_KEY_LOCATION" $*
        elif [[ "$JAVA_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$JAVA_SERVER_PASSWORD" scp $*
        elif [[ "$JAVA_AUTH_MECH" == "NIL" ]]; then
                scp $*
        else
                echo "unexpected token type"; exit;
        fi
}


#echo "1"
IFS="," read -ra servers <<< "$JAVA_SERVERS_IP"
for j in "${servers[@]}"
do


echo  "****************$j************************"

conn_ssh 'bash -s' < ./check_infra.sh

tar=$(conn_ssh which tar)
if [ tar ]; then
        echo "TAR INSTALLED OK"
else
        echo "tar NOT INSTALLED"
	echo "INSTALLING TAR"
        conn_ssh2 "$install_dir"/tar-1.26-35.el7.x86_64.rpm "$JAVA_SERVERS_USERNAME"@"$j":"$INSTALL_DIRECTORY"/tdss/
        conn_ssh sudo yum install -y $INSTALL_DIRECTORY/tdss/tar-1.26-35.el7.x86_64.rpm > /dev/null 2&>1
fi
sshp=$(conn_ssh which sshpass)
if [ sshp ]; then 
        echo "SSHPASS INSTALLED OK"     
else
        echo "SSHPASS  NOT INSTALLED"
	echo "INSTALLING SSHPASS"
        conn_ssh2 "$install_dir"/sshpass-1.06-1.el7.x86_64.rpm "$JAVA_SERVERS_USERNAME"@"$j":"$INSTALL_DIRECTORY"/tdss/
        conn_ssh sudo yum install -y $INSTALL_DIRECTORY/tdss/sshpass-1.06-1.el7.x86_64.rpm > /dev/null 2&>1
fi
result=$(conn_ssh df -h $INSTALL_DIRECTORY | grep -vE '^Size' |awk '{print $4}')
if [[ $result == 200 ]]; then > /dev/null 2&>1
        echo "Available $result OK"
else
        echo "Available $result         Not Supported"
	#exit;
fi

done
