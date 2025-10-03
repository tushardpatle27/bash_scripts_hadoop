service='zookeeper'

if [[ "$service" == 'hadoop' ]]; then
    # For Hadoop
    hadoop fs -ls /
    if [[ ! "$?" -eq 0 ]]; then
        echo "not running"
    fi
elif [[ "$service" == 'mysqld' ]]; then
    if pgrep -x "$service" > /dev/null 2>&1
    then
        pid_num=$(ps -ef | grep mysqld | grep ./bin/mysql | awk '{print $2}')
        echo "Running on PID - '$pid_num'"
    else
        echo "not running"
    fi
elif [[ "$service" == 'hive' ]]; then
    pid_num=$(ps -ef | grep hive | grep metastore | awk '{print $2}')
    if [[ ! -z "$pid_num" ]]; then
        echo "Another Hive Metastore sevice is running on PID - '$pid_num', kill it first"
        exit;
    else 
        echo "not running"
    fi
elif [[ "$service" == 'zookeeper' ]]; then
    pid_num=$(jps | grep QuorumPeerMain | awk '{print $1}')
    if [[ ! -z "$pid_num" ]]; then
        echo "QuorumPeerMain is running on PID - '$pid_num', stop it first"
        exit;
    else
        echo "not running"
    fi
elif [[ "$service" == 'tomee' ]]; then
    pid_num=$(jps | grep Bootstrap | awk '{print $1}')
    if [[ ! -z "$pid_num" ]]; then
        echo "TomEE is running on PID - '$pid_num', stop it first"
        exit;
    else
        echo "not running"
    fi
elif [[ "$service" == 'hbase' ]]; then
    pid_num=$(jps | grep HMaster | awk '{print $1}')
    if [[ ! -z "$pid_num" ]]; then
        echo "HMaster is running on PID - '$pid_num', stop it first"
        exit;
    else
        echo "not running"
    fi
fi

