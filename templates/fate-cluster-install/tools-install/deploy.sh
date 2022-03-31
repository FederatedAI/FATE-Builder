#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
. ${workdir}/conf/setup.conf

/bin/bash ${workdir}/check.sh

if [  ! -f "${pbase}/${pname}/bin/debug" ]
then
  mkdir -p  "${pbase}/${pname}/bin"
  tar xzf   "${workdir}/files/debug.tar.gz" -C "${pbase}/${pname}/bin"
fi
if [  ! -d "${pbase}/${pname}/build" ]
then
  mkdir -p  "${pbase}/${pname}"
  tar xzf   "${workdir}/files/build.tar.gz" -C "${pbase}/${pname}"
fi
if [  ! -d "${pbase}/${pname}/deploy" ]
then
  mkdir -p  "${pbase}/${pname}"
  tar xzf   "${workdir}/files/deploy.tar.gz" -C "${pbase}/${pname}"
fi
