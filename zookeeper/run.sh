#!/bin/bash

ZK_MYID=${ZK_MYID:-"1"}
ZK_NUMBER_OF_NODES=${ZK_NUMBER_OF_NODES:-"1"}
ZK_SERVICE_NAME=${ZK_SERVICE_NAME:-"zookeeper"}

if [[ ${ZK_NUMBER_OF_NODES} > 1 ]]; then
  echo 'standaloneEnabled=false' >> /opt/zookeeper/conf/zoo.cfg
fi

# We do not want to override the dynamic config file.
if [[ ! -f /opt/zookeeper/data/zoo_dynamic.cfg ]]; then
  for n in $(seq 1 ${ZK_NUMBER_OF_NODES}); do
    echo "server.${n}=${ZK_SERVICE_NAME}-${n}:2888:3888;2181" >> /opt/zookeeper/data/zoo_dynamic.cfg
  done
fi

sed -i "s/zookeeper-1/10.0.0.179/g" /opt/zookeeper/data/zoo_dynamic.cfg
sed -i "s/zookeeper-2/10.0.0.221/g" /opt/zookeeper/data/zoo_dynamic.cfg
sed -i "s/zookeeper-3/10.0.0.186/g" /opt/zookeeper/data/zoo_dynamic.cfg

echo ${ZK_MYID} > /opt/zookeeper/data/myid

exec /opt/zookeeper/bin/zkServer.sh start-foreground /opt/zookeeper/conf/zoo.cfg
