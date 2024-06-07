ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as builder
WORKDIR /data/projects/fate/
COPY eggroll.tar.gz .
COPY fate.tar.gz .
COPY conf.tar.gz .
COPY fateflow.tar.gz .
COPY fate.env .
RUN tar -xzf eggroll.tar.gz; \
    tar -xzf fate.tar.gz; \
    tar -xzf conf.tar.gz; \
    tar -xzf fateflow.tar.gz;

RUN ls -l

FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

RUN set -eux; \
    rpm --rebuilddb; \
    rpm --import /etc/pki/rpm-gpg/RPM*; \
    yum install -y which strace java-1.8.0-openjdk ; \
    yum clean all;

WORKDIR /data/projects/fate/eggroll/

COPY --from=builder /data/projects/fate/eggroll /data/projects/fate/eggroll
COPY --from=builder /data/projects/fate/fate /data/projects/fate/fate
COPY --from=builder /data/projects/fate/fateflow /data/projects/fate/fateflow
COPY  --from=builder /data/projects/fate/conf /data/projects/fate/conf
COPY --from=builder /data/projects/fate/fate.env /data/projects/fate/

ENV PYTHONPATH=/data/projects/fate/fate/python:/data/projects/fate/eggroll/python:/data/projects/fate/fateflow/python
ENV EGGROLL_HOME=/data/projects/fate/eggroll/

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
