source ~/.bashrc

cd $HIVE_HOME

echo "Starting Hive metastore"
nohup ./bin/hive --service metastore > curr_log_file 2>&1 &
sleep 5
cat curr_log_file
# pid_num=$(ps -ef | grep hive | grep ./bin/hive | tail -1 | awk '{print $2}')
pid_num=$(ps -ef | grep hive | grep metastore | awk '{print $2}')
echo "Hive Metastore is initiated on PID - '$pid_num'"
exit;