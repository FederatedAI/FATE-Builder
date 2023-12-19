#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

function_check_env() {
  #check java
  if [ ! -f "${javahome}/bin/java" ]
  then
    echo "first install java to ${pbase}/${pname}"
    exit 1;
  fi

  #check python
  if [ ! -f "${pyenv}/bin/python" ]
  then
    echo "first install python and new virtual env ${pyenv}"
    exit 1;
  fi
}

function_install_fate_flow()
{
  local role_name="fate_flow"

  mkdir -p ${pbase}/${pname}/conf

  if [  ! -f "${pbase}/${pname}/fate_flow/python/${role_name}/fate_flow_server.py" ]
  then
    echo "copy ${workdir}/files/fate_flow to ${pbase}/${pname}"
    cp -af "${workdir}/files/fate_flow" "${pbase}/${pname}"
  fi

  if [  ! -f "${pbase}/${pname}/fate/python/__init__.py" ]
  then
    echo "copy ${workdir}/files/fate to ${pbase}/${pname}"
    cp -af "${workdir}/files/fate" "${pbase}/${pname}"
  fi

  ln -frs "${pbase}/${pname}/fate/"{RELEASE.md,fate.env,examples} "${pbase}/${pname}"

  #compute cpu core number
  cores_per_node=$( cat /proc/cpuinfo |grep -cw 'core id' )

  #make settings.py
  echo "partyid:${party_id}"
  variables="pbase=$pbase pname=$pname role_name=${role_name} jbase=$jbase pybase=$pybase party_id=${party_id} fate_flow_ip=${fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort}  fate_flow_grpcPort=${fate_flow_grpcPort} fate_flow_dbname=${fate_flow_dbname} mysql_user=${mysql_user} mysql_pass=${mysql_pass} mysql_ip=${mysql_ip} mysql_port=${mysql_port} redis_ip=${redis_ip} redis_port=${redis_port} redis_pass=${redis_pass} default_storage=${default_storage} fateboard_ip=${fate_flow_ip} fateboard_port=${fateboard_port}  rollsite_ip=${fate_flow_ip} cores_per_node=${cores_per_node} clustermanager_ip=${clustermanager_ip} clustermanager_port=${clustermanager_port}"
  tpl=$( cat ${workdir}/templates/service_conf.yaml.jinja )
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/fate_flow/conf/service_conf.yaml
  ps aux|grep -v grep | grep 'mysql-install/deploy.sh'
  num=$( ps aux|grep -v grep | grep -c 'mysql-install/deploy.sh' )
  while [ $num -ne 0 ]
  do
    ps aux|grep -v grep | grep 'mysql-install/deploy.sh'
    num=$( ps aux|grep -v grep | grep -c 'mysql-install/deploy.sh' )
    echo "sleep 60"
    sleep 60
  done

  if [ ${roles_num} -gt 1 ]; then
    if [ "$group" == "host" ];then
      variables="pbase=$pbase pname=$pname local_fate_flow_ip=${host_fate_flow_ip} other_fate_flow_ip=${guest_fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort} local_id=${host_id} other_id=${guest_id}"
    else
      variables="pbase=$pbase pname=$pname local_fate_flow_ip=${guest_fate_flow_ip} other_fate_flow_ip=${host_fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort} local_id=${guest_id} other_id=${host_id}"
    fi
    tpl=$( cat ${workdir}/templates/double_fate_test_config.yaml.jinja )
  else
    variables="pbase=$pbase pname=$pname fate_flow_ip=${fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort} party_id=${party_id}"
    tpl=$( cat ${workdir}/templates/single_fate_test_config.yaml.jinja )
  fi
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/fate/fate_test/python/fate_test/fate_test_config.yaml

 variables="pbase=$pbase pname=$pname javahome=$javahome pyenv=$pyenv pypath=$pypath egghome=$egghome"
 tpl=$( cat ${workdir}/templates/init_env.sh.jinja )
 printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/fate_flow/bin/init_env.sh
}

function_install_fateboard()
{
  if [  ! -f "${pbase}/${pname}/fateboard/fateboard-${fateboard_version}.jar" ]
  then
    mkdir -p  "${pbase}/${pname}"

    echo "copy ${workdir}/files/fateboard to ${pbase}/${pname}"
    cp -af "${workdir}/files/fateboard" "${pbase}/${pname}"
  fi

  #make application.properties
  echo "partyid:${party_id}"
  variables="pbase=$pbase pname=$pname role_name=${role_name} jbase=$jbase pybase=$pybase party_id=${party_id} fate_flow_ip=${fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort}  fate_flow_grpcPort=${fate_flow_grpcPort} fate_flow_dbname=${fate_flow_dbname} mysql_user=${mysql_user} mysql_pass=${mysql_pass} mysql_ip=${mysql_ip} mysql_port=${mysql_port} redis_ip=${redis_ip} redis_port=${redis_port} redis_pass=${redis_pass} default_storage=${default_storage} fateboard_ip=${fate_flow_ip} fateboard_port=${fateboard_port}  rollsite_ip=${fate_flow_ip} cores_per_node=${cores_per_node}"
  tpl=$( cat ${workdir}/templates/fateboard-application.properties.jinja )
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/fateboard/conf/application.properties
}

function_install_osx()
{
  rm -rf "${pbase}/${pname}/${pname}/proxy/osx/conf/route_table.json"
  cp -af "${pbase}/${pname}/eggroll/conf/route_table.json" "${pbase}/${pname}/${pname}/proxy/osx/conf/broker/route_table.json"

  #make broker.properties
  echo "partyid:${party_id}"
  variables="pbase=$pbase pname=$pname role_name=${role_name} jbase=$jbase pybase=$pybase party_id=${party_id} fate_flow_ip=${fate_flow_ip} fate_flow_httpPort=${fate_flow_httpPort}  fate_flow_grpcPort=${fate_flow_grpcPort} fate_flow_dbname=${fate_flow_dbname} mysql_user=${mysql_user} mysql_pass=${mysql_pass} mysql_ip=${mysql_ip} mysql_port=${mysql_port} redis_ip=${redis_ip} redis_port=${redis_port} redis_pass=${redis_pass} default_storage=${default_storage} fateboard_ip=${fate_flow_ip} fateboard_port=${fateboard_port}  rollsite_ip=${fate_flow_ip} cores_per_node=${cores_per_node}"
  tpl=$( cat ${workdir}/templates/broker.properties.jinja )
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${pname}/proxy/osx/conf/broker/broker.properties
}

group=$1

if [ "$group" != "host" -a "$group" != "guest" ]
then
  echo "$0 host|guest"
  exit 1;
fi

#check env dependency
function_check_env

eval party_id="\${${group}_id}"
eval fate_flow_ip="\${${group}_fate_flow_ip}"
eval mysql_ip="\${${group}_mysql_ip}"
eval redis_ip="\${${group}_redis_ip}"
eval roll_ip="\${${group}_roll_ip}"
eval roll_port="\${${group}_roll_port}"
eval federation_ip="\${${group}_federation_ip}"
eval federation_port="\${${group}_federation_port}"
eval fateboard_ip="\${${group}_fateboard_ip}"
eval fateboard_port="\${${group}_fateboard_port}"
eval rollsite_ip="\${${group}_rollsite_ip}"
eval rollsite_port="\${${group}_rollsite_port}"
eval fatemanager_ip="\${${group}_fatemanager_ip}"
eval fatemanager_port="\${${group}_fatemanager_port}"
eval mysql_pass="\${${group}_mysql_pass}"


#boot servics
for role in ${roles[*]};
do
  case $role in
    "fate_flow")
        function_install_fate_flow
        cd ${pbase}/${pname}/fate_flow/bin;
        source ${pbase}/${pname}/fate_flow/bin/init_env.sh;
        /bin/bash ./service.sh start
      ;;
    "fateboard")
        function_install_fateboard
        cd ${pbase}/${pname}/fateboard;
        source ${pbase}/${pname}/fate_flow/bin/init_env.sh;
        /bin/bash ./service.sh start
      ;;
    "osx")
        function_install_osx
        cd ${pbase}/${pname}/${pname}/proxy/osx;
        source ${pbase}/${pname}/fate_flow/bin/init_env.sh;
	      /bin/bash ${pbase}/${pname}/eggroll/bin/eggroll.sh rollsite stop;
        /bin/bash ./service.sh start
      ;;
    *)
        echo "script not support, please call us"
      ;;
  esac
done

#echeck servics
for role in ${roles[*]};
do
  ps aux|grep -v grep | grep $role;
  num=$( ps aux|grep -v grep|grep -c $role );
  if [ $num -eq 0 ]
  then
    echo "$role not running"
  else
    echo "$role running"
  fi
done

echo "deploy $role ok"

#init flow
mv "${pbase}/${pname}/${pname}/fate_client" "${pbase}/${pname}"
cd ${pbase}/${pname}/fate_client/python
python setup.py install

mv "${pbase}/${pname}/${pname}/fate_test" "${pbase}/${pname}"
cd ${pbase}/${pname}/fate_test/python
python setup.py install

cd ${pbase}/${pname}

echo "flow init  --ip ${fate_flow_ip} --port 9380"
source ${pbase}/${pname}/fate_flow/bin/init_env.sh
flow init  --ip ${fate_flow_ip} --port 9380
#pipeline init --ip "${fate_flow_ip}" --port "${fate_flow_httpPort}"
