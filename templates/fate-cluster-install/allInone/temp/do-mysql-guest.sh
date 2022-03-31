#!/bin/bash

role=guest;

if [ "$role" != "host" -a "$role" != "guest" ]
then
  echo "$0 host|guest"
  exit 1;
fi

cd /data/projects/install;
for name in base-install mysql-install;
do
  echo "++++++++++++deploy $name ++++++++++++++"
  bash ${name}/deploy.sh $role
  echo "+++++++++++++++++++++++++++++++++++++++"
done
