# runtime environment
ARG PREFIX=prefix
ARG BASE_TAG=tag
ARG BASE_IMAGE=image
FROM ${PREFIX}/${BASE_IMAGE}:${BASE_TAG}

COPY requirements.txt /data/projects/python/
RUN sed -i '/torch==1.13.1+cpu\|torchvision==0.14.1+cpu/s/+cpu//g' /data/projects/python/requirements.txt
RUN pip uninstall torch torchvision && pip install --no-cache-dir torch==1.13.1 torchvision==0.14.1
