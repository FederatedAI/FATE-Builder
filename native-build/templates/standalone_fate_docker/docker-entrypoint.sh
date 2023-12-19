#!/bin/bash
set -e

#cd ${WORKDIR}/fate_flow
#bash bin/service.sh start
#
#cd ${WORKDIR}/fateboard
#bash service.sh start

cd ${WORKDIR}
export PYTHONPATH=/data/projects/fate/fate/python:/data/projects/fate/python:/data/projects/fate/fate_flow/python
exec "$@"
