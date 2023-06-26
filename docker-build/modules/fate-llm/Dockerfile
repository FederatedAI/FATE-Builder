# runtime envrionment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as builder

WORKDIR /data/projects/fate/

COPY fate_llm.tar.gz . 

RUN tar -xzf fate_llm.tar.gz;

FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} 

COPY  --from=builder /data/projects/fate/fate_llm /data/projects/fate/fate/

RUN pip install --no-cache-dir -r /data/projects/python/requirements-fate-llm.txt
