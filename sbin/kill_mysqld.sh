source ~/.bashrc
pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | tail -1 | awk '{print $2}')
if [[ ! -z "$pid_num" ]]; then
	echo "Stopping 'mysqld' process - '$pid_num'"
	kill -9 "$pid_num"
else
	echo "MySQL Service is not running to stop"
fi
