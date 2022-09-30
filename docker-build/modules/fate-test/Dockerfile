ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

WORKDIR /data/projects/fate/

ENV PATH=$PATH:/opt/python3/bin/

RUN cd fate; pip install -e python/fate_client; pip install -e python/fate_test; pip install torchvision

COPY test_suite ./test_suite
