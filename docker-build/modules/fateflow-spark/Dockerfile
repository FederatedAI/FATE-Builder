ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

RUN rpm --rebuilddb && \
    rpm --import /etc/pki/rpm-gpg/RPM* && \
    yum install -y  which java-1.8.0-openjdk wget && \
    yum clean all && \
    wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz && \
    tar -xf ./hadoop-3.2.1.tar.gz -C /data/projects/ && rm ./hadoop-3.2.1.tar.gz

RUN wget https://archive.apache.org/dist/spark/spark-3.1.3/spark-3.1.3-bin-hadoop3.2.tgz && \
    tar -xf ./spark-3.1.3-bin-hadoop3.2.tgz -C /data/projects/ && rm ./spark-3.1.3-bin-hadoop3.2.tgz

ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk
ENV SPARK_HOME=/data/projects/spark-3.1.3-bin-hadoop3.2/
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/projects/hadoop-3.2.1/lib/native
ENV PATH=$PATH:/data/projects/spark-3.1.3-bin-hadoop3.2/bin:/data/projects/hadoop-3.2.1/bin

RUN pip install pyspark==3.1.3