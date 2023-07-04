# runtime environment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

RUN pip install --no-cache-dir -r /data/projects/python/requirements-graph-nn.txt
