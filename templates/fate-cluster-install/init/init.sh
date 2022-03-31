#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf


for module in ${modules[*]};
do

  variables="roles_num=${roles_num} host_id=${host_id} guest_id=${guest_id} host_ip=${host_ip} host_mysql_ip=${host_mysql_ip} guest_ip=${guest_ip} guest_mysql_ip=${guest_mysql_ip} pname=${pname} pbase=${pbase} lbase=${lbase} tbase=${tbase} version=${version} user=${user} group=$group host_mysql_pass=${host_mysql_pass} guest_mysql_pass=${guest_mysql_pass} mysql_port=${mysql_port} mysql_admin_pass=${mysql_admin_pass} eggroll_dbname=${eggroll_dbname} fate_flow_dbname=${fate_flow_dbname} rollsite_port=${rollsite_port} clustermanager_port=${clustermanager_port} nodemanager_port=${nodemanager_port} fateflow_grpc_port=${fateflow_grpc_port} fateflow_http_port=${fateflow_http_port} fateboard_port=${fateboard_port}"
  tpl=$( cat ${workdir}/templates/${module}-setup.conf )
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/../${module}-install/conf/setup.conf

  #echo "$module init setup.conf ok"
done
