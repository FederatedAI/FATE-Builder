FROM centos:centos7

ARG version

USER root

WORKDIR /data/projects/python/

COPY requirements.txt /data/projects/python/

RUN set -eux && \
    rpm --rebuilddb && \
    rpm --import /etc/pki/rpm-gpg/RPM* && \
    yum -y install gcc gcc-c++ make openssl-devel gmp-devel mpfr-devel libmpc-devel\
    libmpcdevel libaio numactl autoconf automake libtool libffi-devel  \
    snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4-devel libasan lsof sysstat telnet psmisc && \
    yum clean all

RUN curl -o Python-3.8.13.tar.xz https://www.python.org/ftp/python/3.8.13/Python-3.8.13.tar.xz && \
    tar -xvf Python-3.8.13.tar.xz && \
    cd Python-3.8.13 && \
    ./configure --prefix=/opt/python3 && \
    make altinstall && \
    ln -s /opt/python3/bin/python3.8 /usr/local/bin/python3.8 && \
    ln -s /usr/local/bin/python3.8 /usr/local/bin/python3 && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /opt/python3/bin/pip3.8 /usr/bin/pip3.8 && \
    ln -s /usr/bin/pip3.8 /usr/bin/pip3 && \
    ln -s /usr/bin/pip3 /usr/bin/pip && \
    cd .. && \
    rm Python-3.8.13.tar.xz && \
    rm -rf Python-3.8.13

RUN pip install --upgrade pip && \
    sed -i '/tensorflow.*/d' /data/projects/python/requirements.txt && \
    sed -i '/torch.*/d' /data/projects/python/requirements.txt && \
    sed -i '/torchvision.*/d' /data/projects/python/requirements.txt && \
    sed -i '/pytorch-lightning.*/d' /data/projects/python/requirements.txt && \
    sed -i '/pyspark.*/d' /data/projects/python/requirements.txt && \
    pip install -r requirements.txt
