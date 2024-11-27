#!/bin/bash
set -e

source ${WORKDIR}/bin/init_env.sh

cd ${WORKDIR}/fate_flow
bash bin/service.sh start

cd ${WORKDIR}/fateboard
bash service.sh start

cd ${WORKDIR}
exec "$@"
