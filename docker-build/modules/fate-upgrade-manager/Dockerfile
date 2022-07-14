ARG PREFIX=prefix
ARG BASE_TAG=tag

FROM ${PREFIX}/base-image:${BASE_TAG} as builder

WORKDIR /data/projects/fate/
COPY deploy.tar.gz .

RUN tar -xzf deploy.tar.gz;

FROM centos/python-36-centos7

WORKDIR /
COPY  --from=builder /data/projects/fate/deploy/upgrade/sql ./sql
COPY upgrade-mysql.py .

RUN pip install --upgrade pip && \
    pip install mysql-connector-python
