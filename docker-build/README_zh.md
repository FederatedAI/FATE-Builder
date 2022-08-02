# 构建FATE的镜像

本文主要介绍如何使用FATE的代码构建docker 镜像。

如果您是FATE的用户，您通常不需要从源代码构建FATE。 相反，您可以使用预构建的每个FATE版本准备的docker映像。 它节省了时间并大大简化了FATE的部署过程。 更多详情请参考 [KubeFATE](https://github.com/FederatedAI/KubeFATE)。

一般来说，使用Docker容器来部署和管理应用有如下好处：

1. 减少了依赖的下载
2. 提高编译的效率
3. 一次构建完毕后就可以进行多次部署

## 前期准备

要构建FATE组件的 Docker 镜像，主机必须满足以下要求：

1. Linux 操作系统
2. 主机安装Docker  18或以上版本
3. 主机能够访问互联网

## 构建FATE镜像

### 拉取FATE和FATE-Builder代码库

从FATE的Git Hub代码仓库上通过以下命令获取代码：
  
```bash
git clone https://github.com/FederatedAI/FATE.git
git clone https://github.com/FederatedAI/FATE-Builder.git
```
  
拉取完毕后，进入`FATE-Builder/docker-build/`工作目录。

### 配置镜像（可选）

配置镜像名称
为了减少镜像的容量，我们把镜像划分为以下几类：

- ***基础镜像***： 安装了必要的依赖包，作为模块镜像的基础镜像(Base Image)。
- ***模块镜像***： 包含了FATE中某个特定的模块，它是构建在**基础镜像**上的。

在构建镜像之前，您可以配置 `.env` 文件并将其设置为您自己的镜像 PREFIX 和 TAG。

构建镜像时，基础镜像的命名格式如下：

```bash
<PREFIX>/<image_name>:<BASE_TAG>
```

组件镜像命名格式：

```bash
<PREFIX>/<image_name>:<TAG>
```

**PREFIX**：用于要推送的镜像仓库(Registry)以及其命名空间。
**BASE_TAG**：基础镜像的标签。
**TAG**：组件镜像的标签。

`.env` 的示例如下：

```bash
  PREFIX=federatedai
  BASE_TAG=${version}-release
  TAG=${version}-release
```

**注意：**
如果将 FATE 镜像推送到镜像仓库，则上述配置假定是使用 Docker Hub。 如果使用本地镜像仓库（例如 Harbor）存储图像，请按如下方式更改 `PREFIX`：

```bash
PREFIX=<ip_address_of_registry>/federatedai
```

### 运行构建镜像的脚本

用户可以使用以下命令来构建镜像：

```bash
FATE_DIR=/root/FATE bash build.sh all
```

## 环境变量配置

| name | description | default |
| --- | --- | --- |
| `FATE_DIR` | FATE代码路径 | `/data/projects/fate` |
| `TAG` | 构建镜像的TAG | latest |
| `PREFIX` | 构建镜像的仓库 | federatedai |
| `Docker_Options` | 构建镜像的docker运行参数 | 默认空，可以使用 `--no-cache`去除构建缓存 |
| `Build_Basic` | 构建基本的镜像 | 1 |
| `Build_OP` | 构建拓展的镜像（包含client和fate-test） | 1 |
| `Build_FUM` | 构建FUM镜像 | 1 |
| `Build_NN` | 构建包含NN算法的镜像 | 1 |
| `Build_Spark` | 构建Spark计算引擎的镜像 | 1 |
| `Build_IPCL` | 构建支持IPCL的镜像 | 0 |

所有用于构建镜像的“ Dockerfile”文件都存储在“docker/“子目录下。在脚本运行完之后，用户可以通过以下命令来检查构建好的镜像：

```bash
$ docker images | grep federatedai
REPOSITORY                                       TAG
federatedai/python-nn                            <TAG>
federatedai/fate-test                            <TAG>
federatedai/nginx                                <TAG>
federatedai/spark-master                         <TAG>
federatedai/spark-worker                         <TAG>
federatedai/spark-base                           <TAG>
federatedai/python-spark                         <TAG>
federatedai/client                               <TAG>
federatedai/eggroll                              <TAG>
federatedai/fateboard                            <TAG>
federatedai/python                               <TAG>
federatedai/base-image                           <TAG>
```

### 把镜像推送到镜像仓库（可选）

如果用户需要把构建出来的镜像推送到镜像仓库如DockerHub去的话，需要先通过以下命令登录相应的用户:

```$ docker login username```

然后通过脚本把镜像推送到“.env”定义的命名空间中去:

```$ bash build_cluster_docker.sh push```

默认情况下脚本会把镜像推送到DockerHub上，".env"中的`PREFIX`字段指定了要把镜像要推送到哪个命名空间上。若用户需要把镜像推送到私有的仓库中，只需要把PREFIX字段修改成相应的值即可。

### 使用离线镜像（可选）

对于一些用户而言，他们的机器可能不允许访问互联网，从而无法下载相应的镜像。此时可以将构建好的镜像打包成一个压缩文件，传输到要部署的机器上之后再把镜像解压出来。
因为FATE的部署需要用到mysql的Docker镜像，因此在构建镜像的机器上没有这两个镜像的话还需要手动拉取。拉取及打包镜像的命令如下：

```bash
docker pull mysql
docker save $(docker images | grep -E "mysql" | awk '{print $1":"$2}') -o third-party.images.tar.gz
docker save $(docker images | grep federatedai| grep -v -E "base|builder" | awk '{print $1":"$2}') -o fate.images.tar.gz
```

生成"*.images.tar.gz"文件后，需要将其传输到在运行FATE的主机上，运行以下命令导入镜像：

```bash
docker load -i third-party.images.tar.gz
docker load -i fate.images.tar.gz
```

### 部署

Docker镜像生成后可以使用Docker Compose或Kubernetes来部署FATE，部署步骤请参考Kubefate项目，代码仓库地址：<https://github.com/FederatedAI/KubeFATE>
