ARG LC_ALL=en_US.utf8 LANG=en_US.utf8
ARG WORKDIR=/data/projects/fate

FROM centos:7 AS builder

ARG LC_ALL LANG WORKDIR

WORKDIR $WORKDIR
COPY . .

RUN is_root=1 ./bin/init.sh init && rm -fr env/jdk/jdk-*.tar.xz env/pypi env/python/Miniconda3-*-Linux-x86_64.sh

From centos:7

ARG LC_ALL LANG WORKDIR
ENV LC_ALL=$LC_ALL LANG=$LANG WORKDIR=$WORKDIR
ENV PATH="$WORKDIR/env/python38/venv/bin:$PATH"
ENV PYTHONPATH="$WORKDIR/fate/python:$WORKDIR/eggroll/python"

EXPOSE 8080/tcp 9380/tcp 9380/tcp

WORKDIR $WORKDIR
COPY --from=builder $WORKDIR .

RUN sed -e "s!^mirrorlist=!#mirrorlist=!g" -e "s!^#baseurl=!baseurl=!g" \
  -e "s!http://mirror\.centos\.org!https://mirrors.cloud.tencent.com!g" \
  -i /etc/yum.repos.d/CentOS-*.repo

RUN is_root=1 ./bin/install_os_dependencies.sh && yum clean all

ENTRYPOINT ["/data/projects/fate/env/python/venv/bin/python"]
