#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

if [ $( whoami ) != "root" ]
then
  echo "Warning:  $(whoami ) can su root or sudo?"
fi
#new base
echo "new base directory"
mkdir -p $pbase/$pname
chown $user:$group $pbase/$pname
mkdir -p $tbase
chown $user:$group $tbase

#install dependency packages
#echo "install dependency packages"
#sudo yum -y install gcc  gcc-c++ make openssl-devel gmp-devel mpfr-devel libmpc-devel libaio numactl autoconf automake libtool libffi-devel snappy snappy-devel zlib  zlib-devel bzip2 bzip2-devel lz4-devel libasan lsof sysstat telnet psmisc
bash ${workdir}/install_os_dependencies.sh $user
echo "deploy base ok"
