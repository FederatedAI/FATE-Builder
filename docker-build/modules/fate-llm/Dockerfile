# runtime envrionment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} as builder

WORKDIR /data/projects/fate/

COPY fate_llm.tar.gz . 

RUN tar -xzf fate_llm.tar.gz;

FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG} 

COPY  --from=builder /data/projects/fate/fate_llm /data/projects/fate/fate/

SHELL ["/bin/bash", "-c"]

RUN yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo && \
    yum clean expire-cache && \
    yum install -y libaio-devel && \
    yum install -y cuda-toolkit-11-7.x86_64 --skip-broken && \
    yum install -y cuda-toolkit-11-7.x86_64 && \
    yum install -y cuda-nvcc-11-7.x86_64  && \
    yum clean all && rm -rf /var/cache/yum/* && \
    pip install triton==1.0.0

RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7-gcc*
SHELL ["/usr/bin/scl", "enable", "devtoolset-7"]
RUN gcc --version

RUN echo "source scl_source enable devtoolset-7" >> /etc/bashrc

RUN pip install --no-cache-dir -r /data/projects/python/requirements-fate-llm.txt

RUN yum install -y which && \
    pip uninstall -y deepspeed && \
    DS_BUILD_OPS=1 pip install deepspeed==0.9.2

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV CUDA_HOME=/usr/local/cuda