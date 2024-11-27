ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

WORKDIR /data/projects/fate/

COPY pipeline /data/projects/fate/pipeline
RUN pip install --no-cache-dir notebook markupsafe==2.0.1 peft==0.2.0   -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com

RUN cd /data/projects/fate/; \
    pip install -e fate_client/python/ -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com; \
    pip install -e fate_test/python/ -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com;
ENV FATE_FLOW_IP=fateflow
ENV FATE_FLOW_PORT=9380

CMD pipeline init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && flow init --ip ${FATE_FLOW_IP} --port ${FATE_FLOW_PORT} && jupyter notebook --ip=0.0.0.0 --port=20000 --allow-root --debug --NotebookApp.notebook_dir='/data/projects/fate/' --no-browser --NotebookApp.token='' --NotebookApp.password=''
