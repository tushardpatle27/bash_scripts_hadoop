source ~/.bashrc

pid_num=$(ps -ef | grep hive | grep metastore | grep -v grep|head -1 | awk '{print $2}')
if [[ ! -z "$pid_num" ]]; then
	echo "Stopping 'Hive Metastore service' process - '$pid_num'"
	kill -9 "$pid_num"
else
	echo "Hive Metastore service is not running to stop"
fi
