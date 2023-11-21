#!/bin/bash
set -e

cd ${WORKDIR}/fate_flow
bash bin/service.sh start

cd ${WORKDIR}/fateboard
bash service.sh start

cd ${WORKDIR}
exec "$@"
