#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

echo "install java"
if [ ! -f ${jhome}/jdk-${jversion}/bin/java ]
then
  mkdir -p ${jhome}
  echo "untar ${workdir}/files/jdk-${jversion}.tar.xz to ${jhome}"
  tar xJf ${workdir}/files/jdk-${jversion}.tar.xz -C ${jhome}
fi

echo "deploy java init"
