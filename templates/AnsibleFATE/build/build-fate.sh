#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
cd $workdir
chmod a+x ./bin/*

init() {
  [ ! -d ./conf ] && mkdir ./conf
  if [ "$#" -lt 1 ]; then
    echo "$0 pname [version] [minversion] "
    exit 1;
  fi
  pname=$1
  case $# in
    3)

      version=$2
      minversion=$3
      if [ "$minversion" == "release" ]
      then
        version="${version}"
      else
        version="${version}-${minversion}"
      fi
    ;;

    2)
      version=$2
    ;;

    1)
      version=$( ${workdir}/bin/yq eval '.'"$pname"'|keys|.[0]' ${workdir}/files/fate_product_versions.yml)
    ;;

    *)
      echo "$0 init pname [version] [minversion] "
    ;;
  esac
  echo "$pname: $version"
  isHas=$( ${workdir}/bin/yq eval '.'"$pname"'|has("'"$version"'")' ${workdir}/files/fate_product_versions.yml)
  if [ "$isHas" != "true" ]
  then
    echo "Warning: not support $pname version: ${version}"
    return
  fi
  for name in $( ${workdir}/bin/yq eval '.'"$pname"'."'"$version"'"|keys|.[]' ${workdir}/files/fate_product_versions.yml); do
    tversion=$( ${workdir}/bin/yq eval '.'"$pname"'."'"$version"'".'"$name"'[0]' ${workdir}/files/fate_product_versions.yml )
    if [ "${tversion%-*}" == "${tversion#*-}" ]; then
      eval ${name}_version="${tversion}-release"
    else
      eval ${name}_version="${tversion}"
    fi
  done
  {
  echo "project: $pname"
  echo "products:"
  echo "- fate"
  echo "- eggroll"
  echo "product_fate_version: ${version}"
  echo "product_fate_versions:"
  echo "  fateflow: ${fateflow_version}"
  echo "  fateboard: ${fateboard_version}"
  echo "  eggroll: ${eggroll_version}"
  } > conf/setup.conf
}

get_pinfo() {
  project=$( ${workdir}/bin/yq eval '.project' ${workdir}/conf/setup.conf )
  products=( $( ${workdir}/bin/yq eval '.products.[]' ${workdir}/conf/setup.conf ) )

  echo "project: $project"
  echo "products: ${products[*]}"

  product_fate_version=$( ${workdir}/bin/yq eval '.product_fate_version' ${workdir}/conf/setup.conf )
  echo "fate_version: $product_fate_version"
}


download() {
  url='https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com'

  python='Miniconda3-4.5.4-Linux-x86_64.sh'
  java='jdk-8u192.tar.gz'
  mysql='mysql-8.0.28.tar.gz'
  rabbitmq='rabbitmq-server-generic-unix-3.9.14.tar.xz'
  supervisor='supervisor-4.2.4-py2.py3-none-any.whl'
  pymysql='PyMySQL-1.0.2-py3-none-any.whl'

  if [ ! -f ${workdir}/../roles/python/files/${python} ]; then
    echo "-------------Download mysql package---------"
    echo "+++++++++download: ${workdir}/../roles/python/files/ -o ${url}/${python}"
    wget -P ${workdir}/../roles/python/files/ ${url}/${python}
  fi

  if [ ! -f ${workdir}/../roles/java/files/${java} ]; then
    echo "-------------Download mysql package---------"
    echo "+++++++++download: ${workdir}/../roles/java/files/ -o ${url}/${java}"
    wget -P ${workdir}/../roles/java/files/ ${url}/${java}
  fi

  if [ ! -f ${workdir}/../roles/mysql/files/${mysql} ]; then
    echo "-------------Download mysql package---------"
    echo "+++++++++download: ${workdir}/../roles/mysql/files/ -o ${url}/${mysql}"
    wget -P ${workdir}/../roles/mysql/files/ ${url}/${mysql}
  fi

  if [ ! -f ${workdir}/../roles/rabbitmq/files/${rabbitmq} ]; then
    echo "-------------Download rabbitmq package-----------"
    echo "++++++++++download: ${workdir}/../roles/rabbitmq/files/ -o ${url}/${rabbitmq}"
    wget -P ${workdir}/../roles/rabbitmq/files/ ${url}/${rabbitmq}
  fi

  if [ ! -f ${workdir}/../roles/supervisor/files/${supervisor} ]; then
    echo "-------------Download supervisor package-----------"
    echo "+++++++++download: ${workdir}/../roles/supervisor/files/ -o ${url}/${supervisor}"
    wget -P ${workdir}/../roles/supervisor/files/ ${url}/${supervisor}
  fi

  if [ ! -f ${workdir}/../roles/supervisor/files/${pymysql} ]; then
    echo "-------------Download supervisor package-----------"
    echo "+++++++++download: ${workdir}/../roles/supervisor/files/ -o ${url}/${pymysql}"
    wget -P ${workdir}/../roles/supervisor/files/ ${url}/${pymysql}
  fi

  if [ ! -f ${workdir}/../roles/supervisor/files/${python} ]; then
    echo "-------------Download supervisor package-----------"
    echo "+++++++++link: ${workdir}/../roles/supervisor/files/${python} to ${workdir}/../roles/python/files/${python}"
    ln -frs ${workdir}/../roles/python/files/${python} ${workdir}/../roles/supervisor/files/${python}
  fi

  echo "-------------Download $project package-----------"
  purl="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/$project/${product_fate_version}/release"

  if [ ! -f ../roles/check/files/build.tar.gz -o ! -f ../roles/check/files/deploy.tar.gz ]; then
    echo "+++++++++download: ${purl}/build.tar.gz -o ../roles/check/files/build.tar.gz"
    curl ${purl}/build.tar.gz -o ../roles/check/files/build.tar.gz
    echo "+++++++++download: ${purl}/deploy.tar.gz -o ../roles/check/files/deploy.tar.gz"
    curl ${purl}/deploy.tar.gz -o ../roles/check/files/deploy.tar.gz
  fi

  if [ ! -f ../roles/python/files/pypi.tar.gz -o ! -f ../roles/python/files/requirements.txt ]; then
     echo "+++++++++download: ${purl}/requirements.txt -o ../roles/python/files/requirements.txt"
     curl ${purl}/requirements.txt -o ../roles/python/files/requirements.txt
     echo "+++++++++download: ${purl}/pip-packages-fate-${product_fate_version}.tar.gz -o ../roles/python/files/pypi.tar.gz"
     curl ${purl}/pip-packages-fate-${product_fate_version}.tar.gz -o ../roles/python/files/pypi.tar.gz
  fi

  eggroll_version=$( ${workdir}/bin/yq eval '.product_fate_versions.eggroll' ${workdir}/conf/setup.conf )
  echo "eggroll_version: $eggroll_version"
  if [ ! -f ../roles/eggroll/files/eggroll-${eggroll_version}.tar.gz -o ! -f ../roles/eggroll/files/create-eggroll-meta-tables.sql ]; then
    echo "+++++++++download: ${purl}/eggroll-${eggroll_version}.tar.gz -o ../roles/eggroll/files/eggroll-${eggroll_version}.tar.gz"
    curl ${purl}/eggroll-${eggroll_version}.tar.gz -o ../roles/eggroll/files/eggroll-${eggroll_version}.tar.gz
    echo "+++++++++download: ${purl}/create-eggroll-meta-tables.sql -o ../roles/eggroll/files/create-eggroll-meta-tables.sql"
    curl ${purl}/create-eggroll-meta-tables.sql -o ../roles/eggroll/files/create-eggroll-meta-tables.sql
  fi

  fateflow_version=$( ${workdir}/bin/yq eval '.product_fate_versions.fateflow' ${workdir}/conf/setup.conf )
  echo "fateflow_version: $fateflow_version"
  if [ ! -f ../roles/fateflow/files/fate-${fateflow_version}.tar.gz -o ! -f ../roles/fateflow/files/fateflow-${fateflow_version}.tar.gz ]; then
    echo "+++++++++download: ${purl}/fate-${fateflow_version}.tar.gz -o ../roles/fateflow/files/fate-${fateflow_version}.tar.gz"
    curl ${purl}/fate-${fateflow_version}.tar.gz -o ../roles/fateflow/files/fate-${fateflow_version}.tar.gz
    echo "+++++++++download: ${purl}/fateflow.tar.gz -o ../roles/fateflow/files/fateflow-${fateflow_version}.tar.gz"
    curl ${purl}/fateflow-${fateflow_version}.tar.gz -o ../roles/fateflow/files/fateflow-${fateflow_version}.tar.gz
  fi

  fateboard_version=$( ${workdir}/bin/yq eval '.product_fate_versions.fateboard' ${workdir}/conf/setup.conf )
  echo "fateboard_version: $fateboard_version"
  if [ ! -f ../roles/fateboard/files/fateboard-${fateboard_version}.tar.gz ]; then
    echo "+++++++++download: ${purl}/fateboard-${fateboard_version}.tar.gz -o ../roles/fateboard/files/fateboard-${fateboard_version}.tar.gz"
    curl ${purl}/fateboard-${fateboard_version}.tar.gz -o ../roles/fateboard/files/fateboard-${fateboard_version}.tar.gz
  fi
}

case $1 in
  "init")
    shift
    init $@

    ;;

  "do")
    get_pinfo && download

    ;;

  *)
    echo "Usage: $0 init|do"
    ;;

esac
