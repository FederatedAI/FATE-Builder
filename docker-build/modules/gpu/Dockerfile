# runtime environment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

RUN sed -i '/torch==1.13.1+cpu\|torchvision==0.14.1+cpu/s/+cpu//g' /data/projects/python/requirements.txt && \
    sed -i '/pyspark.*/d' /data/projects/python/requirements.txt && \
    sed -i '/--extra-index-url.*/d' /data/projects/python/requirements.txt && \
    sed -i '/--extra-index-url.*/d' /data/projects/python/requirements-graph-nn.txt && \
    sed -i 's/+pt113cpu//g' /data/projects/python/requirements-graph-nn.txt
RUN pip uninstall -y torch torchvision && pip install --no-cache-dir -r /data/projects/python/requirements.txt && \
    pip install --no-cache-dir -r /data/projects/python/requirements-graph-nn.txt
