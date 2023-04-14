# runtime environment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

COPY requirements.txt /data/projects/python/
RUN sed -i '/pyspark.*/d' /data/projects/python/requirements.txt && \
RUN pip install --no-cache-dir -r /data/projects/python/requirements.txt
