HADOOP Install Bash Scripts - 

1.In this version ,we have removed the user hard coded in scripts and made it automatic .So it is enough to change user name in the config yaml file and run the scripts .
Installation of Software Components:
Download the following package which consists of the libraries and scripts to install the software required for Product Deployment.
http://tookitaki-artifacts.tookitaki.com/artifactory/Software-packages/v5/softcomponents_hadoop_v5.0.2.tar.gz
The following are the dirs in the main directory of the above-downloaded file:
bin (Main installation scripts)
conf (COnfiguration files)
lib (Software dir)
sbin (Start and stop scripts of services)
temp (intermediate dir to store deployment files)
Enter the required environmental variables in the conf/config.yaml file:
INSTALL_DIRECTORY=  /local/1/  (Base directory in which installation would be performed)
Installation Properties
 

 
After adding the required details in the conf/config.yaml file, execute the following files from the bin in the same order:
Make sure which user you want to install these scripts i.e ec2-user or tookitaki user and change user name in config.yaml file.
           a. cd softcomponents_hadoop_v5.0.2/bin
           b. sh install_java.sh    
           c.sh zookeeper_setup.sh   
           d. sh  hadoop_ha_setup.sh  
           e . sh  hbase_install.sh 
2. i) Before executing Hive script ,if you want to use RDS for hive metastore ,you no need to run mysql setup script ,just enter RDS server ip in config.yaml and  validate mysql connection .
           f. validate_mysql.sh   ---> This will validate mysql connection 
    ii) If you want to use mysql database for hive metastore ,Then execute mysql_setup.sh script .
         g. sh mysql_setup.sh
    iii)  Finally run hive script after you choose anyone of the 2 options .
       h. sh hive_setup.sh
Validations:
Start hadoop :
/home/ec2-user/tdss/hadoop/sbin/start-all.sh
or 
/home/tookitaki/tdss/hadoop/sbin/start-all.sh
stop hadoop :
/home/ec2-user/tdss/hadoop/sbin/stop-all.sh
or
/home/tookitaki/tdss/hadoop/sbin/stop-all.sh
start hbase : 
/home/ec2-user/tdss/hbase/bin/start-hbase.sh
or
/home/tookitaki/tdss/hbase/bin/start-hbase.sh
stop hbase :
/home/ec2-user/tdss/hbase/bin/stop-hbase.sh
or
/home/tookitaki/tdss/hbase/bin/stop-hbase.sh
Start hive : 
nohup hive --service metastore &
stop hive : 
ps -ef | grep hive 
kill hive metastore process id .

---------------------------------------


Note - 

add this files in libs from apache website archives - 

softcomponents_hadoop_v5.0.2/libs

tusharpatle@ip-192-168-1-4 libs % du -s -h *
312M	apache-hive-3.1.3-bin.tar.gz
 12M	apache-zookeeper-3.7.1-bin.tar.gz
669M	hadoop-3.3.4.tar.gz
272M	hbase-2.4.14-bin.tar.gz
143M	jdk-8u351-linux-x64.tar.gz
 28K	libaio-0.3.109-13.el7.x86_64.rpm
619M	mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz
864K	mysql-connector-java.jar
198M	phoenix-hbase-2.4-5.1.2-bin.tar.gz
4.0K	wget-log.1
