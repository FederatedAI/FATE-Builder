#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

echo "Install python"

#install base python
if [ ! -f ${pydir}/bin/python ]
then
  mkdir -p ${pydir%/*}
  bash ${workdir}/files/Miniconda3-*-Linux-x86_64.sh -b -p ${pydir}
fi

if [ ! -f ${pyenv}/bin/python ]
then
  ${pydir}/bin/pip install -U -f ${workdir}/files/pypkg --no-index virtualenv

  #install python env
  ${pydir}/bin/virtualenv -p ${pydir}/bin/python3.6 --no-download ${pyenv}
  source ${pyenv}/bin/activate
  pip install -U -f ${workdir}/files/pypkg --no-index pip setuptools wheel

  #install fate python dependency package
  echo "pip install -U -r ${workdir}/files/requirements.txt -f ${workdir}/files/pypkg --no-index"
  pip install -U -r ${workdir}/files/requirements.txt -f ${workdir}/files/pypkg --no-index
  pnum=$( pip list | wc -l )
  rnum=$( grep -cE '=|>|<' ${workdir}/files/requirements.txt  )
  echo "install: $pnum require: $rnum"
  if [ $pnum -lt $rnum ]
  then
    pip install -U -r ${workdir}/files/requirements.txt -f ${workdir}/files/pypkg --no-index
  fi
fi

echo "deploy python ok"
