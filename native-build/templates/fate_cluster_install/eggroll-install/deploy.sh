#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

group="$1"
if [ "$group" != "host" -a "$group" != "guest" ]
then
  echo "$0 host|guest"
  exit 1
fi

if [ ! -f "${javahome}/bin/java" ]
then
  echo "first install java to ${pbase}/${pname}"
  exit 1;
fi

if [ ! -f "${pyenv}/bin/python" ]
then
  echo "first install python and new virtual env ${pyenv}"
  exit 1;
fi

eval id=\${${group}_id}
eval rollsite_ip=\${${group}_rollsite_ip}
eval rollsite_port=\${${group}_rollsite_port}
eval fateflow_ip=\${${group}_fateflow_ip}
eval fateflow_port=\${${group}_fateflow_port}
eval clustermanager_ip=\${${group}_clustermanager_ip}
eval eggroll_db_ip="\${${group}_eggroll_db_ip}"
#eval eggroll_db_port="\${${group}_eggroll_db_port}"
eval eggroll_db_passwd="\${${group}_eggroll_db_passwd}"

if [  ! -f "${pbase}/${pname}/${role_name}" ]
then
  mkdir -p "${pbase}/${pname}"
  echo "copy ${workdir}/files/${role_name} to ${pbase}/${pname}"
  cp -af "${workdir}/files/${role_name}" "${pbase}/${pname}"
fi

mkdir -p  "${pbase}/${pname}/bin"

if [ ${roles_num} -gt 1 ]; then
  if [ "$group" == "host" ];then
    variables="local_fateflow_ip=${host_fateflow_ip} local_fateflow_port=${host_fateflow_port} local_rollsite_ip=${host_rollsite_ip} local_rollsite_port=${host_rollsite_port} other_rollsite_ip=${guest_rollsite_ip} other_rollsite_port=${guest_rollsite_port} local_id=${host_id} other_id=${guest_id}"
  else
    variables="local_fateflow_ip=${guest_fateflow_ip} local_fateflow_port=${guest_fateflow_port} local_rollsite_ip=${guest_rollsite_ip} local_rollsite_port=${guest_rollsite_port} other_rollsite_ip=${host_rollsite_ip} other_rollsite_port=${host_rollsite_port} local_id=${guest_id} other_id=${host_id}"
  fi
  tpl=$( cat ${workdir}/templates/double_route_table.json.jinja )
else
  variables="rollsite_ip=${rollsite_ip} rollsite_port=${rollsite_port} fateflow_ip=${fateflow_ip} fateflow_port=${fateflow_port} id=${id}"
  tpl=$( cat ${workdir}/templates/single_route_table.json.jinja )
fi
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${role_name}/conf/route_table.json

variables="pbase=$pbase pname=$pname javahome=$javahome pyenv=$pyenv pypath=$pypath id=$id rollsite_ip=${rollsite_ip} rollsite_port=${rollsite_port} clustermanager_ip=${clustermanager_ip} clustermanager_port=${clustermanager_port} nodemanager_port=${nodemanager_port} eggroll_db_ip=${eggroll_db_ip} eggroll_db_port=${eggroll_db_port} eggroll_db_name=${eggroll_db_name} eggroll_db_username=${eggroll_db_username} eggroll_db_passwd=${eggroll_db_passwd} coordinator=$coordinator pyenv=$pyenv javahome=$javahome role=$group pypath=$pypath "
tpl=$( cat ${workdir}/templates/eggroll.properties.jinja )
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${role_name}/conf/eggroll.properties

variables="pbase=$pbase pname=$pname javahome=$javahome pyenv=$pyenv pypath=$pypath egghome=$egghome"
tpl=$( cat ${workdir}/templates/init_env.sh.jinja )
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/bin/init_env.sh
#sed -i '/FATE_PROJECT_BASE=/i\fate_project_base=$(cd `dirname "$(realpath "${BASH_SOURCE[0]:-${(%):-%x}}")"`; cd ../;pwd)' ${pbase}/${pname}/bin/init_env.sh


for role in ${roles[*]};
do
  cd ${pbase}/${pname}/${role_name};
  source ${pbase}/${pname}/bin/init_env.sh;
  /bin/bash bin/eggroll.sh $role start;
done

num=$( ps aux|grep -v grep |grep -c "fate" );
if [ $num -lt ${#roles[*]} ]
then
    echo "$role running may be wrong"
else
    echo "$role running ok"
fi

echo "deploy $role ok"
