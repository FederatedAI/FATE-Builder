# runtime envrionment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as builder

WORKDIR /data/projects/fate/

COPY fate.tar.gz .
COPY fate_flow.tar.gz .
COPY fate_client.tar.gz .
COPY fate_test.tar.gz .
COPY eggroll.tar.gz .
COPY examples.tar.gz .
COPY doc.tar.gz .

RUN tar -xzf fate.tar.gz; \
    tar -xzf fate_flow.tar.gz; \
    tar -xzf fate_client.tar.gz; \
    tar -xzf fate_test.tar.gz; \
    tar -xzf eggroll.tar.gz; \
    tar -xzf examples.tar.gz; \
    tar -xzf doc.tar.gz; 

FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} 

WORKDIR /data/projects/fate

COPY  --from=builder /data/projects/fate/fate /data/projects/fate/fate
COPY  --from=builder /data/projects/fate/examples /data/projects/fate/examples
COPY  --from=builder /data/projects/fate/doc /data/projects/fate/doc

COPY --from=builder /data/projects/fate/eggroll /data/projects/fate/eggroll
COPY --from=builder /data/projects/fate/fate_flow /data/projects/fate/fate_flow
COPY --from=builder /data/projects/fate/fate_client /data/projects/fate/fate_client
COPY --from=builder /data/projects/fate/fate_test /data/projects/fate/fate_test

ENV PYTHONPATH=/data/projects/fate/fate/python:/data/projects/fate/fate_flow/python
ENV EGGROLL_HOME=/data/projects/fate/eggroll
ENV FATE_PROJECT_BASE=/data/projects/fate

RUN pip install werkzeug cryptography; \
    pip install -r /data/projects/fate/fate_flow/python/requirements-flow.txt; \
    pip install -r /data/projects/python/requirements-fate.txt;

CMD ["/bin/bash", "-c", "sleep 5 && python fate_flow/python/fate_flow/fate_flow_server.py"]