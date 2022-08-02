ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as data

# TODO pip pkg install

FROM python:3.6

WORKDIR /data/projects/fate/

COPY pipeline /data/projects/fate/pipeline
RUN pip install notebook fate-client pandas sklearn
RUN mkdir /data/projects/fate/logs
COPY --from=data /data/projects/fate/examples /data/projects/fate/examples
COPY --from=data /data/projects/fate/fateflow/examples /data/projects/fate/fateflow/examples

ENV FATE_FLOW_IP=fateflow
ENV FATE_FLOW_PORT=9380

CMD flow init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && pipeline init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && jupyter notebook --ip=0.0.0.0 --port=20000 --allow-root --debug --NotebookApp.notebook_dir='/data/projects/fate/' --no-browser --NotebookApp.token='' --NotebookApp.password=''
