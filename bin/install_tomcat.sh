source ../conf/config.yaml  > /dev/null 2>&1
install_dir=../libs
#set -e
conn_web(){

        if [[ "$TOMCAT_AUTH_MECH" == "KEY" ]];then
                ssh -i "$TOMCAT_SERVER_KEY_LOCATION"  "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$TOMCAT_SERVER_PASSWORD" "$TOMCAT_SERVER_USERNAME"@"$t" $*
        elif [[ "$TOMCAT_AUTH_MECH" == "NIL" ]]; then
                ssh "$TOMCAT_SERVER_USERNAME"@"$t" $*
        else
                echo "unexpected token type"; exit;
        fi
}
conn_web2(){
         if [[ "$TOMCAT_AUTH_MECH" == "KEY" ]];then
                scp -i "$TOMCAT_SERVER_KEY_LOCATION" $*
        elif [[ "$TOMCAT_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$TOMCAT_SERVER_PASSWORD" scp $*
        elif [[ "$TOMCAT_AUTH_MECH" == "NIL" ]]; then
                scp $*
        else
                echo "unexpected token type"; exit;
        fi

}
IFS="," read -ra servers <<< "$TOMCAT_SERVERS_IP"
for t in "${servers[@]}"
do
echo "Installing Tomcat"
conn_web rm -r "$INSTALL_DIRECTORY"/tdss/tomcat > /dev/null 2&>1
#conn_web2 "../$install_dir"/* "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/
conn_web2 "$install_dir"/apache-tomcat-10.0.23.tar.gz "$TOMCAT_SERVER_USERNAME"@"$t":"$INSTALL_DIRECTORY"/tdss/
conn_web tar -xf "$INSTALL_DIRECTORY"/tdss/apache-tomcat-10.0.23.tar.gz -C"$INSTALL_DIRECTORY"/tdss/
conn_web mv "$INSTALL_DIRECTORY"/tdss/apache-tomcat-10.0.23 "$INSTALL_DIRECTORY"/tdss/tomcat
echo "export CATALINA_HOME="$INSTALL_DIRECTORY"/tdss/tomcat/" | conn_web "cat >> ~/.bashrc"
conn_web sed -i "s@8080@$TOMCAT_PORT@" "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml

if [[ "$IS_SSL_REQUIRED" == "YES" ]] && [[ "$SS" == "YES" ]];
 then
 sh Tomcat_ssl_gen.sh
 sleep 3
 cp -r ../src/tomcat_server_ssl_templete.xml "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
 conn_web sed -i "s:"filepath":"$certificateKeystoreFile":" "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
 conn_web sed -i "s:"password":"$certificateKeystorePassword":" "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
elif [[ "$IS_SSL_REQUIRED" == "YES" ]] && [[ "$SS" == "NO" ]];
 then
	 if [[ -r $certificateKeystoreFile ]]
	 then
 cp -r ../src/tomcat_server_ssl_templete.xml "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
 conn_web sed -i "s:"filepath":"$certificateKeystoreFile":" "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
 conn_web sed -i "s:"password":"$certificateKeystorePassword":" "$INSTALL_DIRECTORY"/tdss/tomcat/conf/server.xml
         else
		 echo "File does not have permissions $certificateKeystoreFile, Aborting script"
		 exit
	 fi
fi


conn_web rm -r "$INSTALL_DIRECTORY"/tdss/apache-tomcat-10.0.23.tar.gz
echo "Starting Tomcat"
conn_web "$INSTALL_DIRECTORY"/tdss/tomcat/bin/shutdown.sh > /dev/null 2&>1
conn_web jps | grep Bootstrap | grep -v grep | awk '{print $1}' | xargs kill > /dev/null 2&>1
conn_web "$INSTALL_DIRECTORY"/tdss/tomcat/bin/startup.sh
#conn_web netstat -tunlpe | grep 8081 | grep -v grep | awk '{print $9}' 

test=$(conn_web jps | grep Bootstrap | awk '{print $2}')
result=$(conn_web "if [[ test = Bootstrap ]]; then echo "installed"; else echo "not installed"; fi")
if [[ $result == "installed" ]]; then
        echo "Aborting.."
        exit;
else
         echo "Tomcat is Installed and URL is http/s://$TOMCAT_SERVERS_IP:$TOMCAT_PORT/8443"
fi
done
