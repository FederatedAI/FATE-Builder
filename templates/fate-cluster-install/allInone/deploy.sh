#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

. ${workdir}/conf/setup.conf

mkdir -p "${workdir}/logs"

function_init() {
  local module="init"
  local roles_num=${#roles[*]}
  variables="roles_num=${roles_num} host_id=${host_id} guest_id=${guest_id} host_ip=${host_ip} host_mysql_ip=${host_mysql_ip} guest_ip=${guest_ip} guest_mysql_ip=${guest_mysql_ip} pbase=${pbase} tbase=${tbase} pname=${pname} lbase=${lbase} version=${version} user=${ssh_user} group=${ssh_group} mysql_port=${mysql_port}  host_mysql_pass=${host_mysql_pass} guest_mysql_pass=${guest_mysql_pass} eggroll_dbname=${eggroll_dbname} fate_flow_dbname=${fate_flow_dbname} mysql_admin_pass=${mysql_admin_pass} redis_pass=${redis_pass} rollsite_port=${rollsite_port} clustermanager_port=${clustermanager_port} nodemanager_port=${nodemanager_port} fateflow_grpc_port=${fateflow_grpc_port} fateflow_http_port=${fateflow_http_port} fateboard_port=${fateboard_port}"
  tpl=$( cat ${workdir}/templates/${module}-setup.conf )
  printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/../${module}/conf/setup.conf
  /bin/bash ${workdir}/../${module}/init.sh
  echo "init over" > ${workdir}/logs/deploy.log
}

function_deploy() {

  date > ${workdir}/logs/time
  tmodules=()
  for module in ${basemodules[*]}
  do
    tmodules=( ${tmodules[*]} ${module}-install )
  done
  cd ${workdir}/../

  for role in ${roles[*]};
  do
    case $role in
      "host")
        for ip in "${host_ip}";
        do
          echo "goto $ip"
          ssh -p ${ssh_port} ${ssh_user}@${ip} "sudo mkdir -p $pbase; sudo chown ${ssh_user}:${ssh_group} $pbase"
          tar czf -  ${tmodules[*]} | ssh -p ${ssh_port} ${ssh_user}@${ip} "mkdir -p $pbase/install; cd $pbase/install; tar zxvf -"
          variables="pbase=$pbase pname=$pname role=host"
          tpl=$( cat ${workdir}/templates/do.sh.jinja )
          printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/temp/do-host.sh
          cat ${workdir}/temp/do-host.sh | ssh -p ${ssh_port} ${ssh_user}@${ip} /bin/bash
          echo "deploy host $ip  over" >> ${workdir}/logs/deploy.log
          echo "--------done---------"
          date >> ${workdir}/logs/time
        done > ${workdir}/logs/deploy-host.log 2>&1 &

        for ip in "${host_mysql_ip}";
        do
          echo "goto $ip"
          ssh -p ${ssh_port} ${ssh_user}@${ip} "sudo mkdir -p $pbase; sudo chown ${ssh_user}:${ssh_group} $pbase"
          tar czf -  ${dbmodules[*]}-install | ssh -p ${ssh_port} ${ssh_user}@${ip} "mkdir -p $pbase/install; cd $pbase/install; tar zxvf -"
          variables="pbase=$pbase role=host"
          tpl=$( cat ${workdir}/templates/do-mysql.sh.jinja )
          printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/temp/do-mysql-host.sh
          cat ${workdir}/temp/do-mysql-host.sh | ssh -p ${ssh_port} ${ssh_user}@${ip} /bin/bash
          echo "--------done---------"
          echo "deploy host mysql $ip  over" >> ${workdir}/logs/deploy.log
          date >> ${workdir}/logs/time
        done > ${workdir}/logs/deploy-mysql-host.log 2>&1 &
      ;;

      "guest")

        for ip in "${guest_ip}";
        do
          echo "goto $ip"
          ssh -p ${ssh_port} ${ssh_user}@${ip} "sudo mkdir -p $pbase; sudo chown ${ssh_user}:${ssh_group} $pbase"
          tar czf -  ${tmodules[*]} | ssh -p ${ssh_port} ${ssh_user}@${ip} "mkdir -p $pbase/install; cd $pbase/install; tar zxvf -"
          variables="pbase=$pbase pname=$pname role=guest"
          tpl=$( cat ${workdir}/templates/do.sh.jinja )
          printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/temp/do-guest.sh
          cat ${workdir}/temp/do-guest.sh | ssh -p ${ssh_port} ${ssh_user}@${ip} /bin/bash
          echo "deploy guest $ip  over" >> ${workdir}/logs/deploy.log
          echo "--------done---------"
          date >> ${workdir}/logs/time
        done > ${workdir}/logs/deploy-guest.log 2>&1 &

        for ip in "${guest_mysql_ip}";
        do
          echo "goto $ip"
          ssh -p ${ssh_port} ${ssh_user}@${ip} "sudo mkdir -p $pbase; sudo chown ${ssh_user}:${ssh_group} $pbase"
          tar czf -  ${dbmodules[*]}-install | ssh -p ${ssh_port} ${ssh_user}@${ip} "mkdir -p $pbase/install; cd $pbase/install; tar zxvf -"
          variables="pbase=$pbase role=guest"
          tpl=$( cat ${workdir}/templates/do-mysql.sh.jinja )
          printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ${workdir}/temp/do-mysql-guest.sh
          cat ${workdir}/temp/do-mysql-guest.sh | ssh -p ${ssh_port} ${ssh_user}@${ip} /bin/bash
          echo "deploy guest mysql  $ip  over" >> ${workdir}/logs/deploy.log
          echo "--------done---------"
          date >> ${workdir}/logs/time
        done > ${workdir}/logs/deploy-mysql-guest.log 2>&1 &
      ;;
    esac
  done
}

action=$1
case $action in

  "init")
    echo "init args"
    function_init
  ;;

  "go")
    echo "deploy"
    function_deploy
  ;;

  "help")
    echo "usage: $0 init|deploy"
  ;;

  *)
    echo "init args"
    function_init
    echo "deploy"
    function_deploy
  ;;

esac
