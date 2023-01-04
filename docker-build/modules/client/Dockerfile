ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as data

WORKDIR /data/projects/fate/

RUN cd /data/projects/fate/fate/python/fate_client; \
    python setup.py bdist_wheel;

FROM python:3.8

WORKDIR /data/projects/fate/

RUN apt-get update && apt-get install -y vim && apt-get clean

COPY pipeline /data/projects/fate/pipeline
RUN pip install notebook torch pandas sklearn markupsafe==2.0.1
RUN mkdir /data/projects/fate/logs
COPY --from=data /data/projects/fate/examples /data/projects/fate/examples
COPY --from=data /data/projects/fate/fateflow/examples /data/projects/fate/fateflow/examples
COPY --from=data /data/projects/fate/fate/python/fate_client/dist/fate_client-*-py3-none-any.whl /data/projects/fate/
RUN cd /data/projects/fate/; pip install fate_client-*-py3-none-any.whl; rm fate_client-*-py3-none-any.whl

ENV FATE_FLOW_IP=fateflow
ENV FATE_FLOW_PORT=9380

CMD flow init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && pipeline init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && jupyter notebook --ip=0.0.0.0 --port=20000 --allow-root --debug --NotebookApp.notebook_dir='/data/projects/fate/' --no-browser --NotebookApp.token='' --NotebookApp.password=''
