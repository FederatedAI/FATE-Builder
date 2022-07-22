# runtime environment
ARG PREFIX=prefix
ARG BASE_TAG=tag
FROM ${PREFIX}/fateflow:${BASE_TAG}

COPY requirements.txt /data/projects/python/
RUN pip install -r /data/projects/python/requirements.txt
