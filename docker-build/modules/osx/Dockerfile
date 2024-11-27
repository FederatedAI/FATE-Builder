FROM maven:3.6-jdk-8 as builder
WORKDIR /data/projects/fate/
COPY osx.tar.gz .
RUN tar -xvzf osx.tar.gz ;\
    cd osx; \
    bash deploy/auto-package.sh

FROM mcr.microsoft.com/java/jre:8u192-zulu-alpine
WORKDIR /data/projects/fate/osx/

COPY --from=builder /data/projects/fate/osx/deploy/osx.tar.gz /data/projects/fate/
RUN cd /data/projects/fate/; tar -xvf osx.tar.gz
EXPOSE 9370 9883

CMD java -server -Xms2g -Xmx2g -XX:+UseG1GC -XX:G1HeapRegionSize=16m -XX:G1ReservePercent=25 -XX:InitiatingHeapOccupancyPercent=30 -XX:SoftRefLRUPolicyMSPerMB=0 -verbose:gc -Xloggc:/dev/shm/rmq_srv_gc_%p_%t.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCApplicationStoppedTime -XX:+PrintAdaptiveSizePolicy -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=30m -XX:-OmitStackTraceInFastThrow -XX:+AlwaysPreTouch -XX:MaxDirectMemorySize=15g -XX:-UseLargePages -XX:-UseBiasedLocking -cp conf/broker/:lib/* com.osx.broker.Bootstrap -c /data/projects/fate/osx/conf/broker/broker.properties
