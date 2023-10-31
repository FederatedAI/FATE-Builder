ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

WORKDIR /data/projects/fate/

ENV PATH=$PATH:/opt/python3/bin/

COPY test_suite ./test_suite
