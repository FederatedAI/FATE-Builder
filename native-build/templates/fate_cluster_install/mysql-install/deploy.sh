#!/usr/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

group="$1"

role_name="mysql"

if [ "$group" != "host" -a "$group" != "guest" ]
then
  echo "$0 host|guest"
  exit 1;
fi

#new base dir
mkdir -p  "${pbase}/${pname}/${mysql_path}" "${lbase}/${pname}/${role_name}"  "${pbase}/${pname}/data/mysql"

#unzip mysql
if [ ! -d "${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}" ]
then
  echo "untar ${workdir}/files/${role_name}-${mysql_version}.tar.gz to ${pbase}/${pname}/${mysql_path}"
  tar xzf ${workdir}/files/${role_name}-${mysql_version}.tar.gz -C ${pbase}/${pname}/${mysql_path} && mkdir -pv ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/{conf,run,sql,logs} ${pbase}/${pname}/data/${role_name}
fi

#make $pbase/$pname/${mysql_path}/${role_name}-${mysql_version}/conf/my.cnf
#eval mysql_port=\${${group}_mysql_port}
variables="lbase=${lbase} pbase=$pbase pname=$pname role_name=${role_name} mysql_port=${mysql_port} mysql_path=${mysql_path} mysql_version=${mysql_version}"
tpl=`cat ${workdir}/templates/my.cnf.jinja`
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > $pbase/$pname/${mysql_path}/${role_name}-${mysql_version}/conf/my.cnf

#make ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/load.sh
variables="pbase=$pbase lbase=$lbase pname=$pname eggroll_dbname=${eggroll_dbname} role_name=${role_name} ver=$pversion mysql_path=${mysql_path} mbase=${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version} mysql_port=${mysql_port} mysql_admin_user=${mysql_admin_user} base=${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}"
tpl=`cat ${workdir}/templates/load.sh.jinja`
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/load.sh

#make ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/init.sh
variables="pbase=$pbase lbase=$lbase pname=$pname role_name=${role_name} ver=$pversion mysql_path=${mysql_path} mbase=${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}"
tpl=`cat ${workdir}/templates/init.sh.jinja`
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/init.sh

#make ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/chpasswd.sh
variables="pbase=$pbase lbase=$lbase pname=$pname role_name=${role_name} mysql_port=${mysql_port} mysql_path=${mysql_path}  mbase=${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version} mysql_admin_user=${mysql_admin_user}"
tpl=`cat ${workdir}/templates/chpasswd.sh.jinja`
printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/chpasswd.sh

#cp /create-eggroll-meta-tables.sql
cp ${workdir}/files/create-eggroll-meta-tables.sql  ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/sql/
cp ${workdir}/templates/service.sh  ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/

#make ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/sql/insert-node.sql
eval clustermanager_ip=\${${group}_clustermanager_ip}
eval nodemanager_ips=\${${group}_nodemanager_ips}
eval mysql_user=\${${group}_mysql_user}
eval mysql_pass=\${${group}_mysql_pass}
{
echo "CREATE DATABASE IF NOT EXISTS ${fate_flow_dbname};"
echo "CREATE USER ${mysql_user}@'${clustermanager_ip%:*}' IDENTIFIED BY '${mysql_pass}';"
echo "GRANT ALL ON ${fate_flow_dbname}.* TO ${mysql_user}@'${clustermanager_ip%:*}';"
echo "GRANT ALL ON ${eggroll_dbname}.* TO ${mysql_user}@'${clustermanager_ip%:*}';"
echo "use ${eggroll_dbname};"
echo "INSERT INTO server_node (host, port, node_type, status) values ('${clustermanager_ip%:*}', '${clustermanager_ip#*:}', 'CLUSTER_MANAGER', 'HEALTHY');"
for temp in ${nodemanager_ips[*]}
do
echo "INSERT INTO server_node (host, port, node_type, status) values ('${temp%:*}', '${temp#*:}', 'NODE_MANAGER', 'HEALTHY');"
if [  ${temp%:*} != ${clustermanager_ip%:*} ]
then
  echo "CREATE USER ${mysql_user}@'${temp%:*}' IDENTIFIED BY '${mysql_pass}';"
  echo "GRANT ALL ON ${fate_flow_dbname}.* TO ${mysql_user}@'${temp%:*}';"
  echo "GRANT ALL ON ${eggroll_dbname}.* TO ${mysql_user}@'${temp%:*}';"
fi
done

} >  ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/sql/insert-node.sql

if [ ! -f ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/.init ]
then
  #init mysql
  /bin/bash ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/init.sh
  sleep 10
  #boot mysql
  nohup $pbase/$pname/${mysql_path}/${role_name}-${mysql_version}/bin/mysqld_safe --defaults-file=$pbase/$pname/${mysql_path}/${role_name}-${mysql_version}/conf/my.cnf --user=`whoami` >> $pbase/$pname/${mysql_path}/${role_name}-${mysql_version}/logs/mysqld.log 2>&1 &
  sleep 10

  num=$( ps aux|grep -v grep |grep -c mysql )
  if [ "$num" -gt 0 ]
  then
    if [ ! -f ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/.chpasswd ]
    then
      #change mysql passwd
      /bin/bash ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/chpasswd.sh ${mysql_admin_pass}
    fi

    if [ ! -f ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/.load ]
    then
      #load mysql data
      /bin/bash -x ${pbase}/${pname}/${mysql_path}/${role_name}-${mysql_version}/load.sh ${mysql_admin_pass}
    fi
  fi

fi

echo "deploy mysql ok"
