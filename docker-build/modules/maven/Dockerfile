FROM maven:3.8-jdk-8
 
# 设置Maven的本地仓库路径
ARG MAVEN_OPTS="-Dmaven.repo.local=/.m2/repository"
 
# 设置环境变量
ENV MAVEN_OPTS $MAVEN_OPTS
 
# 复制项目的pom.xml文件和源代码到容器中
COPY ./pom.xml /usr/src/app/pom.xml
COPY ./src /usr/src/app/src
 
# 构建项目
RUN mvn -f /usr/src/app/pom.xml clean package
 
# 运行项目
CMD ["mvn", "-f", "/usr/src/app/pom.xml", "exec:java"]

