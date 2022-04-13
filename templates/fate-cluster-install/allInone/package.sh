#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
. ${workdir}/conf/setup.conf

if [ ! -d "$workdir/build/temp" ]
then
  mkdir -p ${workdir}/../build/temp
fi

if [ "$#" -ne 2 ]
then
  echo "[error]: $0 need three parameters {minversion lastversion}"
  exit 1;
fi

function package_cp() {
  parm1=$1
  parm2=$2
  echo -e "----$parm1 md5 has changed----"
  echo -e "cp -vf ${parm1} ${workdir}/../${parm2}/files/${parm1}"
  cp -vf ${parm1} "${workdir}/../${parm2}/files/${parm1}"
  ls -l "${workdir}/../${parm2}/files/${parm1}"
  echo -e "\n"
}

minversion=$1
lastversion=$2
url="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com"
eversion=2.4.0
cd ${workdir}/../build

if [ -n "$minversion" ]
then
  echo "---------------Download $version $minversion packages---------------"
  for temp in "bin" "conf" "build" "deploy" "fate" "fateflow" "examples" "fateboard"; do
    curl -o ${temp}.tar.gz ${url}/fate/${version}/${minversion}/${temp}.tar.gz
  done
  curl -o eggroll.tar.gz ${url}/eggroll/${eversion}/release/eggroll.tar.gz
  curl -o fate.env ${url}/fate/${version}/${minversion}/fate.env
  curl -o RELEASE.md ${url}/fate/${version}/${minversion}/RELEASE.md
  curl -o requirements.txt ${url}/fate/${version}/${minversion}/requirements.txt
fi

if [ -n "$lastversion" ]
then
  echo "---------------Download $version $lastversion packages---------------"
  for temp in "bin" "conf" "build" "deploy" "fate" "fateflow" "examples" "fateboard"; do
    curl -o ./temp/${temp}.tar.gz ${url}/fate/${version}/${lastversion}/${temp}.tar.gz
  done
  curl -o ./temp/eggroll.tar.gz ${url}/eggroll/${eversion}/release/eggroll.tar.gz
  curl -o ./temp/fate.env ${url}/fate/${version}/${lastversion}/fate.env
  curl -o ./temp/RELEASE.md ${url}/fate/${version}/${lastversion}/RELEASE.md
  curl -o ./temp/requirements.txt ${url}/fate/${version}/${lastversion}/requirements.txt
fi

if [ ! -f "./bin.tar.gz" -o ! -f "./temp/bin.tar.gz" ]; then
  echo "ERROR: some packages not exists"
  exit 1
else
  curl -o packages_md5.txt ${url}/fate/${version}/${minversion}/packages_md5.txt
  packages_md5=()
  value=`cat packages_md5.txt`
  for name in "bin" "conf" "build" "deploy" "fate" "fateflow" "examples" "fateboard" "eggroll"
  do
    package_name=$name".tar.gz"
    package_md5=`md5sum ${package_name} |awk '{print $1}'`
    packages_md5=( ${packages_md5[*]} $name':'$package_md5 )
  done
  declare -a result_list
  t=0
  flag=0
  for m in ${packages_md5[@]};do
    for n in ${value[*]};do
      if [ "$m" = "$n" ];then
        echo -e "The $m md5 value matches successfully\n"
        flag=1
        break
      fi
    done
    if [ $flag -eq 0 ]; then
      result_list[t]=$m
      t=$((t+1))
    else
      flag=0
    fi
  done
  if [[ -n $result_list ]];then
    echo -e "The ${result_list[*]} md5 value matches failed\n"
    exit 1
  fi
  if [ $? -eq 0 ];then
    cp -f build.tar.gz ${workdir}/../tools-install/files/
    cp -f deploy.tar.gz ${workdir}/../tools-install/files/

    mv fate.tar.gz fate-${version}.tar.gz
    mv fateflow.tar.gz fateflow-${version}.tar.gz
    mv fateboard.tar.gz fateboard-${version}.tar.gz
    mv eggroll.tar.gz eggroll-${version}.tar.gz
    mv ./temp/fate.tar.gz ./temp/fate-${version}.tar.gz
    mv ./temp/fateflow.tar.gz ./temp/fateflow-${version}.tar.gz
    mv ./temp/fateboard.tar.gz ./temp/fateboard-${version}.tar.gz
    mv ./temp/eggroll.tar.gz ./temp/eggroll-${version}.tar.gz
  fi

  for pkname in "eggroll-${version}.tar.gz" "fateboard-${version}.tar.gz" "fate-${version}.tar.gz" "fateflow-${version}.tar.gz" "RELEASE.md" "requirements.txt" "fate.env" "conf.tar.gz" "bin.tar.gz"
  do
    md5_new=`md5sum $pkname | awk '{print $1}'`
    md5_old=`md5sum ${workdir}/../build/temp/${pkname} | awk '{print $1}'`
    if [ ${md5_new} = ${md5_old} ];then
      echo -e "****${pkname} md5 no change****\n"
      continue
    fi
    if [ $pkname = "conf.tar.gz" ];then
      tar xf $pkname
      echo -e "----$pkname md5 has changed----\n"
      echo -e "cp -vf conf/rabbitmq_route_table.yaml ${workdir}/../fate-install/files/rabbitmq_route_table.yaml"
      cp -vf conf/rabbitmq_route_table.yaml ${workdir}/../fate-install/files/rabbitmq_route_table.yaml
      ls -l ${workdir}/../fate-install/files/rabbitmq_route_table.yaml
      echo -e "\n"
      continue
    fi
    if [ $pkname = "bin.tar.gz" ];then
      tar xf $pkname
      echo -e "----$pkname md5 has changed----\n"
      echo -e "cp -vf install_os_dependencies.sh ${workdir}/../base-install/install_os_dependencies.sh"
      cp -vf bin/install_os_dependencies.sh ${workdir}/../base-install/install_os_dependencies.sh
      ls -l ${workdir}/../base-install/install_os_dependencies.sh
      tar xf ${workdir}/../build/temp/${pkname} -C ${workdir}/../build/temp/
      temp=$( diff bin/init_env.sh ./temp/bin/init_env.sh )
      if [[ -n $temp ]]; then
        echo -e "\n-----please check manually init_env.sh is there ant change----------\n"
      fi
      continue
    fi
    if [ $pkname = "eggroll-${version}.tar.gz" ];then
      package_cp $pkname eggroll-install
      continue
    fi
    if [ $pkname = "requirements.txt" ];then
      package_cp $pkname python-install
      wget -P ${workdir}/../build ${url}/fate/${version}/${minversion}/pypkg.tar.gz
      echo -e "\ncp -vf ${workdir}/../build/pypkg.tar.gz ${workdir}/../python-install/files/pypkg.tar.gz\n"
      cp -vf ${workdir}/../build/pypkg.tar.gz ${workdir}/../python-install/files/pypkg.tar.gz
      ls -l ${workdir}/../python-install/files/
      echo -e "\n"
      continue
    fi
    package_cp $pkname fate-install
  done
fi

rm -rf $workdir/../build/*
