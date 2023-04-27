ARG PREFIX=prefix
ARG BASE_TAG=tag
FROM centos/python-38-centos7 as builder

USER root
# upgrade gcc
RUN yum install -y flex devtoolset-8 numactl-devel centos-release-scl wget git numactl-devel gmp-devel mpfr-devel libssl
SHELL ["/usr/bin/scl", "enable", "devtoolset-8"]

ENV PATH=${PATH}:/opt/python3/bin/

RUN pip install --no-cache-dir cmake==3.22 wheel

# install nasm
RUN wget --no-check-certificate https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.gz \
    && tar zxf nasm-2.15.05.tar.gz && cd nasm-2.15.05 \
    && ./configure --prefix=/usr/local/nasm && make -j && make install \
    && ln -s /usr/local/nasm/bin/nasm /usr/bin/nasm \
    && ln -s /usr/local/nasm/bin/ndisasm /usr/bin/ndisasm \
    && cd .. && rm -rf nasm-*

# install openssl
RUN wget --no-check-certificate http://www.openssl.org/source/openssl-1.1.0l.tar.gz \
    && tar zxf openssl-1.1.0l.tar.gz && cd openssl-1.1.0l \
    && ./config --prefix=/usr/local/openssl && make -j && make install \
    && ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl \
    && echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && ldconfig -v \
    && cd .. && rm -rf openssl-*
ENV OPENSSL_ROOT_DIR=/usr/local/openssl

WORKDIR /data/projects/fate/
ENV WORKDIR /data/projects/fate

COPY ipcl_pkg.tar.gz .
RUN tar -xzf ipcl_pkg.tar.gz

ENV IPCL_DIR=${WORKDIR}/ipcl_pkg/ipcl
RUN cd ./ipcl_pkg/ && python setup.py bdist_wheel

FROM ${PREFIX}/base-image:${BASE_TAG} 

RUN yum install -y wget

# install openssl
RUN wget --no-check-certificate http://www.openssl.org/source/openssl-1.1.0l.tar.gz \
    && tar zxf openssl-1.1.0l.tar.gz && cd openssl-1.1.0l \
    && ./config --prefix=/usr/local/openssl && make -j && make install \
    && ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl \
    && echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && ldconfig -v \
    && cd .. && rm -rf openssl-*
ENV OPENSSL_ROOT_DIR=/usr/local/openssl

# install ipcl-python
WORKDIR /data/projects/fate/
ENV WORKDIR /data/projects/fate
COPY --from=builder /data/projects/fate/ipcl_pkg/dist/ipcl_python-1.1.3-cp38-cp38-linux_x86_64.whl .

ENV IPCL_DIR=${WORKDIR}/ipcl_pkg/ipcl
RUN pip install ipcl_python-1.1.3-cp38-cp38-linux_x86_64.whl \
    && rm -rf ipcl_python-1.1.3-cp38-cp38-linux_x86_64.whl
