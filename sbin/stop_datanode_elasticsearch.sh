source ../conf/config.yaml  > /dev/null 2>&1
install_dir=../libs
#set -e
conn_web(){

        if [[ "$ES_AUTH_MECH" == "KEY" ]];then
                ssh -i "$ES_SERVER_KEY_LOCATION"  "$ES_SERVER_USERNAME"@"$t" $*
        elif [[ "$ES_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$ES_SERVER_PASSWORD" "$ES_SERVER_USERNAME"@"$t" $*
        elif [[ "$ES_AUTH_MECH" == "NIL" ]]; then
                ssh "$ES_SERVER_USERNAME"@"$t" $*
        else
                echo "unexpected token type"; exit;
        fi
}
conn_web2(){
         if [[ "$ES_AUTH_MECH" == "KEY" ]];then
                scp -i "$ES_SERVER_KEY_LOCATION" $*
        elif [[ "$ES_AUTH_MECH" == "PASS" ]]; then
                sshpass -p "$ES_SERVER_PASSWORD" scp $*
        elif [[ "$ES_AUTH_MECH" == "NIL" ]]; then
                scp $*
        else
                echo "unexpected token type"; exit;
        fi

}
echo $ES_DATANODE_SERVERS_IP
IFS="," read -ra servers <<< "$ES_DATANODE_SERVERS_IP"
for t in "${servers[@]}"
do
echo "Stop ElasticSearch & RNI "
#conn_web jps | grep Elasticsearch | grep -v grep | awk '{print $1}' | xargs kill -9 > /dev/null 2&>1
conn_web pkill -f elasticsearch 
conn_web netstat -tunlpe | grep 9200 | grep -v grep | awk '{print $9}' | xargs kill -9 > /dev/null 2&>1
test=$(conn_web jps | grep Elasticsearch | awk '{print $2}')
result=$(conn_web "if [[ test= ]]; then echo "Stoped"; else echo "not Stoped"; fi")
if [[ $result == "Stoped" ]]; then
        echo "ElasticSearch Stoped scuccessfull"
        
else
        echo "ElasticSearch is runing Still"
fi
done
