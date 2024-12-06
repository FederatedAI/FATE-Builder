FROM centos:centos7

ARG version

USER root
WORKDIR /data/projects/python/
ENV VIRTUAL_ENV /data/projects/python/venv

RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo && \
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo && \
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
RUN set -eux && \
    rpm --rebuilddb && \
    rpm --import /etc/pki/rpm-gpg/RPM* && \
    yum -y install gcc gcc-c++ make openssl=1.1.1f openssl-devel supervisor gmp-devel mpfr-devel libmpc-devel \
    libaio numactl autoconf automake libtool libffi-devel snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4-devel libasan lsof xz-devel sqlite-devel && \
    yum clean all
RUN curl -o openssl-1.1.1d.tar.gz https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/openssl-1.1.1d.tar.gz && \
    tar -zxvf openssl-1.1.1d.tar.gz && \
    cd openssl-1.1.1d && \
    ./config --prefix=/usr/local/openssl && \
    make && make install && \
    #mv /usr/bin/openssl /usr/bin/openssl.bak && \
    ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl && \
    echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && \
    ldconfig -v && \
    rm -rf openssl-1.1.1d && \
    rm -rf openssl-1.1.1d.tar.gz

RUN curl -o Python-3.10.14.tar.xz https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/Python-3.10.14.tar.xz && \
    tar -xvf Python-3.10.14.tar.xz && \
    cd Python-3.10.14 && \
    ./configure --prefix=/opt/python3  --with-openssl=/usr/local/openssl  && \
    make -j && make install && \
    ln -s /opt/python3/bin/python3.10 /usr/local/bin/python3.10 && \
    ln -s /usr/local/bin/python3.10 /usr/local/bin/python3 && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /opt/python3/bin/pip3.10 /usr/bin/pip3.10 && \
    ln -s /usr/bin/pip3.10 /usr/bin/pip3 && \
    ln -s /usr/bin/pip3 /usr/bin/pip && \
    cd .. && \
    whereis pip && \
    rm Python-3.10.14.tar.xz && \
    rm -rf Python-3.10.14
#RUN curl -o Miniconda3-py310_24.5.0-0-Linux-x86_64.sh https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/Miniconda3-py310_24.5.0-0-Linux-x86_64.sh && \
#    chmod +x ./Miniconda3-py310_24.5.0-0-Linux-x86_64.sh 
#CMD ["/bin/bash", "-c", "./Miniconda3-py310_24.5.0-0-Linux-x86_64.sh -b -f -p  /data/projects/python/"]
#&&  ./Miniconda3-py310_24.5.0-0-Linux-x86_64.sh && \

#RUN /data/projects/python/bin/pip install virtualenv   -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com && \
#    /data/projects/python/bin/pip install setuptool  -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com && \
#    /data/projects/python/bin/pip install wheel  -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements*.txt ./

RUN pip install --upgrade pip  -i https://mirrors.cloud.tencent.com/pypi/simple --trusted-host mirrors.cloud.tencent.com
