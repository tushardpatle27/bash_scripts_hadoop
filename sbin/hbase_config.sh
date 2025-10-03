{ # try
hadoopmaster=`grep "\<HADOOP_CLUSTER_NAME\>" ../conf/config.yaml  | sed s/.*://g`
zooservers=`grep "\<HADOOP_HA_MASTER_SERVERS\>" ../conf/config.yaml  | sed s/.*://g | sed '2d'`
zoodatadir=`grep "\<ZOOKEEPER_DATA_DIR\>" ../conf/config.yaml  | sed s/.*://g`


hadoopmaster=${hadoopmaster//[[:space:]]/}
zooservers=${zooservers//[[:space:]]/}
zoodatadir=${zoodatadir//[[:space:]]/}

#Generate hbase regions
cat ../conf/config.yaml | grep ^HBASE_REGION_IP | cut -d ":" -f 2 | sed 's/,/'\\\n'/g' > ../conf/hbase/config_template/master/regionservers

cat ../conf/config.yaml | grep ^HBASE_REGION_IP | cut -d ":" -f 2 | sed 's/,/'\\\n'/g' > ../conf/hbase/config_template/slave/regionservers

#Generate backup-master

cat ../conf/config.yaml | grep ^HBASE_BACKUP_MASTERS | cut -d ":" -f 2 | sed 's/,/'\\\n'/g' > ../conf/hbase/config_template/master/backup-masters

cat ../conf/config.yaml | grep ^HBASE_BACKUP_MASTERS | cut -d ":" -f 2 | sed 's/,/'\\\n'/g' > ../conf/hbase/config_template/slave/backup-masters


eval "cat <<EOF
$(<../conf/hbase/config_template/master/hbase-site.xml)
EOF
" | tee ../conf/hbase/generated_hbase_config/master/hbase-site.xml
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/master/hbase-site.xml

} || { # catch
    echo "Error! unable to create MASTER hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/slave/hbase-site.xml)
EOF
" | tee ../conf/hbase/generated_hbase_config/slave/hbase-site.xml
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/slave/hbase-site.xml

} || { # catch
    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/hbase-env.sh)
EOF
" | tee ../conf/hbase/generated_hbase_config/hbase-env.sh
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/hbase-env.sh

} || { # catch
i    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/master/regionservers)
EOF
" | tee ../conf/hbase/generated_hbase_config/master/regionservers
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/master/regionservers

} || { # catch
    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/slave/regionservers)
EOF
" | tee ../conf/hbase/generated_hbase_config/slave/regionservers
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/slave/regionservers

} || { # catch
    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/master/backup-masters)
EOF
" | tee ../conf/hbase/generated_hbase_config/master/backup-masters
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/master/backup-masters

} || { # catch
    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}
{
eval "cat <<EOF
$(<../conf/hbase/config_template/slave/backup-masters)
EOF
" | tee ../conf/hbase/generated_hbase_config/slave/backup-masters
sed -i -e 's,//,/,g' ../conf/hbase/generated_hbase_config/slave/backup-masters

} || { # catch
    echo "Error! unable to create SLAVE hbase-site.xml for deployment as specified in conf file"
    echo $?
    exit 1
}


