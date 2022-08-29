#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

echo "install java"
if [ ! -f ${jhome}/jdk-8u192/bin/java ]
then
  mkdir -p ${jhome}
  echo "untar ${workdir}/files/*.gz to ${jhome}"
  tar xzf ${workdir}/files/*.gz -C ${jhome}
fi

echo "deploy java init"
