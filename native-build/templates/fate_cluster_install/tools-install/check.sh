#!/bin/bash

export PATH=$PATH:/usr/sbin:/bin
#check sudo
if [ $( whoami ) != "root" ]
then
  echo "Warning: $(whoami ) has sudo privilege?"
fi

# check utf-8
if [[ ! "${LANG,,}" =~ utf-?8$ ]]; then
    echo 'Warning: please set $LANG to a UTF-8 Locale. E.g.: export LANG=en_US.UTF-8'
fi

#check open files and max user process
ulimit  -a |egrep 'open files|max user processes'|awk '{ if($1$2 == "openfiles") { if(  $4 <  64000 ) print "Warning: now open files is "$4", and need to turn up to 64000";} if( $1$2$3 == "maxuserprocesses" ) { if(  $5 < 65535 ) print "Warning: now max user processes is "$5", and need to turn up to 65535";} }'

#check swap
mem=$(free -g|grep 'Mem:'|awk '{ print $2; }' )
free -g|grep 'Swap'|awk '{ if( int($2) < '"$(( 128-$mem))"' ) print "Warning: now swap is "$2", need to turn up"; }'

#check fate process
pnum=$( ps aux|egrep -v "grep|fate/tools/check.sh|serving|ansilbe|tail|" | grep -c fate );
if [ $pnum -gt 0 ]
then
  echo "Warning: key fate process exists, please has a check and clean"
fi

#check port
open_ports=( $(  ss -lnt|grep 'LISTEN'|grep -v ':::' | awk '{print ; }'|cut -d : -f 2|sort -u ) )
tports=()
for oport in ${open_ports[*]};
do
  for port in "9370" "4670" "4671" "9360" "9380" "3306";
  do
    if [ $oport == $port ]
    then
      tports=( ${tports[*]} $port )
    fi
  done
done
if [ ${#tports[*]} -gt 0 ]
then
  echo "Warning: these ports: ${tports[*]} have been used"
fi

#check mysql
if [ -f /etc/my.cnf ]
then
  echo "Warning: if install mysql, please stop mysql, and rename /etc/my.cnf"
fi

if [ -d "/data/projects/fate" ]
then
  echo "Waring: if install mysql, please rename /data/projects/fate"
fi

if [ -d "/data/projects/data/fate/mysql" ]
then
  echo "Warning: if install mysql, please rename /data/projects/data/fate/mysql"
fi
