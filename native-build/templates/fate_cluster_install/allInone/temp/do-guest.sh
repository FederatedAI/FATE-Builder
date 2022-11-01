#!/bin/bash

role=guest;

if [ "$role" != "host" -a "$role" != "guest" ]
then
  echo "$0 host|guest"
  exit 1;
fi
export PATH=/data/projects/fate/common/python/venv/bin:/data/projects/serving_2.0.4/jdk/jdk-8u345/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/nemo/jdk8/bin:/data/projects/common/kubernetes/bin:/root/bin:/data/projects/common/hadoop/bin:/data/projects/common/hadoop/sbin:/data/projects/common/spark:/root/bin:/data/projects/common/erlang/bin:/data/projects/dxm/apache-jmeter-5.1.1/bin:/root/bin:/bin:/root/bin:/data/projects/zhou/apache-maven-3.8.2/bin:/home/app/.local/bin:/home/app/bin:/data/projects/fate/common/jdk/jdk-8u345/bin:/usr/sbin:/usr/bin:/bin
cd /data/projects/install;
for name in tools-install base-install java-install python-install eggroll-install fate-install;
do
  echo "+++++++++++++++deploy $name +++++++++++++++"
  bash ${name}/deploy.sh $role
  echo "+++++++++++++++++++++++++++++++++++++++++++"
done

ps aux|grep -v grep | grep 'mysql-install/deploy.sh'
num=$( ps aux|grep -v grep | grep -c 'mysql-install/deploy.sh' )
while [ $num -ne 0 ]
do
  ps aux|grep -v grep | grep 'mysql-install/deploy.sh'
  num=$( ps aux|grep -v grep | grep -c 'mysql-install/deploy.sh' )
  echo "sleep 2"
  sleep 2
done

source /data/projects/fate/bin/init_env.sh
echo "restart fate_flow"
cd /data/projects/fate/fateflow/bin
/bin/bash ./service.sh restart
