ARG PREFIX=prefix
ARG BASE_TAG=tag
FROM ${PREFIX}/base-image:${BASE_TAG} 


# upgrade gcc
RUN yum install -y flex devtoolset-8 numactl-devel
SHELL ["/usr/bin/scl", "enable", "devtoolset-8"]

# install cmake
# RUN wget http://cmake.org/files/v3.22/cmake-3.22.0.tar.gz \
#     && tar zxf cmake-3.22.0.tar.gz && cd cmake-3.22.0 \
#     && ./configure && make install -j \
#     && cd .. && rm -rf cmake-*
RUN pip install cmake==3.22

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
COPY ipcl_demo.tar.gz .
RUN tar -xzf ipcl_pkg.tar.gz; \
    tar -xzf ipcl_demo.tar.gz;

# install ipcl-python
ENV IPCL_DIR=${WORKDIR}/ipcl_pkg/ipcl
RUN cd ./ipcl_pkg/ipcl-python/ && python setup.py install
