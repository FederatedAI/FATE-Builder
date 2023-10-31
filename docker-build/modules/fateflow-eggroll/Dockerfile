# runtime envrionment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as builder

RUN pip install -r /data/projects/python/requirements-eggroll.txt

ENV PYTHONPATH=/data/projects/fate/fate/python:/data/projects/fate/fate_flow/python:/data/projects/fate/eggroll/python