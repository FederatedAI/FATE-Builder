FROM ubuntu:20.04

RUN sed -i 's/archive.ubuntu.com/mirrors.cloud.tencent.com/g;\
            s/security.ubuntu.com/mirrors.cloud.tencent.com/g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates
RUN sed -i 's#http://#https://#g' /etc/apt/sources.list
RUN apt-get update && apt-get -y --no-install-recommends dist-upgrade

RUN echo 'Asia/Shanghai' > /etc/timezone
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

RUN apt-get install -y --no-install-recommends python3-pip npm maven
RUN rm -fr /var/lib/apt/lists/*

RUN mkdir -p /root/.config/pip
RUN echo '\
[global]\n\
index-url = https://mirrors.cloud.tencent.com/pypi/simple\n\
' > /root/.config/pip/pip.conf

RUN echo '\
registry=https://mirrors.cloud.tencent.com/npm/\n\
disturl=https://mirrors.cloud.tencent.com/nodejs-release/\n\
' > /root/.npmrc

RUN mkdir -p /root/.m2
RUN echo '\
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"\n\
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n\
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">\n\
  <mirrors>\n\
    <mirror>\n\
      <id>maven-tencentyun</id>\n\
      <mirrorOf>*</mirrorOf>\n\
      <name>Tencent Repository Mirror</name>\n\
      <url>https://mirrors.cloud.tencent.com/nexus/repository/maven-public/</url>\n\
    </mirror>\n\
  </mirrors>\n\
</settings>\n\
' > /root/.m2/settings.xml
