ARG LC_ALL=en_US.utf8 LANG=en_US.utf8
ARG WORKDIR=/data/projects/fate

FROM centos:7 AS builder

ARG LC_ALL LANG WORKDIR

WORKDIR $WORKDIR
COPY . .

RUN is_root=1 ./bin/init.sh init && rm -fr env/jdk/*.tar.gz env/pypi env/python/*.sh

From centos:7

ARG LC_ALL LANG WORKDIR
ENV LC_ALL=$LC_ALL LANG=$LANG WORKDIR=$WORKDIR
ENV PATH="$WORKDIR/env/python38/venv/bin:$PATH"

EXPOSE 8080/tcp 9380/tcp 9380/tcp

WORKDIR $WORKDIR
COPY --from=builder $WORKDIR .

RUN is_root=1 ./bin/install_os_dependencies.sh && yum clean all

ENTRYPOINT ["./bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
