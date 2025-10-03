source ~/.bashrc

hadoop fs -mkdir -p /jobhistory/logs

$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver
