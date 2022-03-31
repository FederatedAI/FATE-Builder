#!/bin/bash

role=host;

if [ "$role" != "host" -a "$role" != "guest" ]
then
  echo "$0 host|guest"
  exit 1;
fi
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/nemo/jdk8/bin:/home/app/.local/bin:/home/app/bin:/usr/sbin:/usr/bin:/bin
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
