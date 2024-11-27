FROM mcr.microsoft.com/java/jre:8u192-zulu-alpine as builder
WORKDIR /data/projects/fate/
COPY fate_board.tar.gz .
RUN tar -xzf fate_board.tar.gz 

FROM mcr.microsoft.com/java/jre:8u192-zulu-alpine
RUN apk add tzdata
WORKDIR /data/projects/fate/fate_board/

COPY --from=builder /data/projects/fate/fate_board /data/projects/fate/fate_board
EXPOSE 8080

CMD java -Dspring.config.location=/data/projects/fate/fate_board/conf/application.properties -Dssh_config_file=/data/projects/fate/fate_board/ssh/ -Xmx2048m -Xms2048m -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError -cp /data/projects/fate/fate_board/lib/*:/data/projects/fate/fate_board/fateboard-2.1.0.jar org.fedai.fate.board.bootstrap.Bootstrap
#CMD java -Dspring.config.location=/data/projects/fate/fate_board/conf/application.properties  -Dssh_config_file=/data/projects/fate/fate_board/conf  -Xmx2048m -Xms2048m -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError  -jar fateboard.jar
