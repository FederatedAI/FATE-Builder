#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

echo "Install python"

now=$( date +%s ); mkdir -p ${tbase}/fate-python-$now;

#install base python
if [ ! -f ${pydir}/bin/python ]
then
  mkdir -p ${pydir%/*}
  bash ${workdir}/files/Miniconda3-*-Linux-x86_64.sh -b -p ${pydir}
fi

if [ ! -f ${pyenv}/bin/python ]
then
  ${pydir}/bin/pip install virtualenv -f ${workdir}/files --no-index
  if [ ! -d "${workdir}/files/pypi" ]
  then
    mkdir -pv ${workdir}/files/
    cd ${workdir}/files/
    echo "untar ${workdir}/files/pypi.tar.gz"
    tar xzf ${workdir}/files/pypi.tar.gz
  fi
  #install python env
  ${pydir}/bin/virtualenv -p ${pydir}/bin/python3.6  --no-wheel --no-setuptools --no-download ${pyenv}
  source ${pyenv}/bin/activate
  pip install ${workdir}/files/setuptools-50.3.2-py3-none-any.whl
  #install fate python dependency package
  echo "pip install -r ${workdir}/files/requirements.txt -b ${tbase}/fate-python-$now -f ${workdir}/files/pypi --no-index"
  pip install -r ${workdir}/files/requirements.txt -b ${tbase}/fate-python-$now -f ${workdir}/files/pypi --no-index
  pnum=$( pip list | wc -l )
  rnum=$( grep -cE '=|>|<' ${workdir}/files/requirements.txt  )
  echo "install: $pnum require: $rnum"
  if [ $pnum -lt $rnum ]
  then
    pip install -r ${workdir}/files/requirements.txt -b ${tbase}/fate-python-$now -f ${workdir}/files/pypi --no-index
  fi
fi

rm -rf ${tbase}/fate-python-$now
echo "deploy python ok"
