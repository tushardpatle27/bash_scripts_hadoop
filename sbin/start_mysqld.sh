source ~/.bashrc
pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | awk '{print $2}')
if [[ ! -z "$pid_num" ]]; then
    echo "Another MySQL Sevice is running on PID - '$pid_num', kill it first"
    exit;
else
    cd $MYSQL_HOME
    nohup ./bin/mysqld > curr_log_file 2>&1 &
    sleep 5
    cat curr_log_file

    pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | tail -1 | awk '{print $2}')
    # validate
	if grep -q "ready for connections" curr_log_file; then
		echo "'mysqld' is initiated on PID - '$pid_num'"
	else
		echo "'mysqld' is not ready for connections"
		echo "Killing '$pid_num'"
		kill -9 "$pid_num"
		exit 1;
	fi
    exit;
fi
