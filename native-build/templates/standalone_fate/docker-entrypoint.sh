#!/bin/bash
set -e

cd ${WORKDIR}/fateflow
bash bin/service.sh start

cd ${WORKDIR}/fateboard
bash service.sh start

cd ${WORKDIR}
exec "$@"
