# Building FATE Images

This document provides guidance on how to build Docker images for FATE from source code.

If you are a user of FATE, you usually DO NOT need to build FATE from source code. Instead, you can use the pre-built docker images for each release of FATE. It saves time and greatly simplifies the deployment process of FATE. Refer to  [KubeFATE](https://github.com/FederatedAI/KubeFATE) for more details.

In general, using Docker containers to deploy and manage applications has the following benefits:

1. Reduced dependency downloads
2. Improve the efficiency of compilation
3. After one build, you can deploy multiple times

## Prerequisites

To build the Docker images of FATE components, the host must meet the following requirements:

1. A Linux host
2. Docker 18+
3. The host can access the Internet.
4. Root user authority

## Building images of FATE

### Pull FATE and FATE-Builder code base

Get the code from FATE's Git Hub code repository with the following command:
  
```bash
git clone https://github.com/FederatedAI/FATE.git
git clone https://github.com/FederatedAI/FATE-Builder.git
```
  
After pulling, go to the `FATE-Builder/docker-build/` working directory.

### Configuration (optional)

To reduce the size of images, a few base images are created first. Other images are then built on top of the base images. They are described as follows:

- ***base images***: contain the minimum dependencies of  components of FATE.
- ***component images*** contain a specific component of FATE, it is built on the top of ***base image***

Before building the image, you can configure the `.env` file and set it as your own image PREFIX and TAG.

When images are built, base images have the naming format as follows:

```bash
<PREFIX>/<image_name>:<BASE_TAG>
```

and component images have the below naming format:

```bash
<PREFIX>/<image_name>:<TAG>
```

**PREFIX**: the namespace on the registry's server, it will be used to compose the image name.  
**BASE_TAG**: tag used for base images.  
**TAG**: tag used for component images.

A sample of `.env` is as follows:

```bash
PREFIX=federatedai
BASE_TAG=${version}-release
TAG=${version}-release
```

**NOTE:**
If the FATE images will be pushed to a registry server, the above configuration assumes the use of Docker Hub. If a local registry (e.g. Harbor) is used for storing images, change the `PREFIX` as follows:

```bash
PREFIX=<ip_address_of_registry>/federatedai
```

### Running the build script

After configuring `.env`, use the following command to build all images:

```bash
FATE_DIR=/root/FATE bash build.sh all
```

## Environments

| name | description | default |
| --- | --- | --- |
| `FATE_DIR` | the directory of FATE | `/data/projects/fate` |
| `TAG` |  build images tag | latest |
| `PREFIX` | build images prefix | federatedai |
| `Docker_Options` | build images docker options | The default is empty, you can use `--no-cache` to remove the build cache |
| `Build_Basic` | build basic images | 1 |
| `Build_OP` | build optional images (including client and fate-test) | 1 |
| `Build_FUM` | build FUM images | 0 |
| `Build_NN` | Build images containing the NN algorithm | 1 |
| `Build_Spark` | Build images of the Spark computing engine | 1 |
| `Build_IPCL` | Build images that supports IPCL | 0 |
| `IPCL_PKG_DIR` | IPCL code path ｜ None ｜
| `IPCL_VERSION` | IPCL version ｜ v1.1.3 ｜
| `Build_GPU` | Build images that supports GPU | 0 |
| `Build_LLM` | Build images that supports FATE-LLM | 0 |
| `Build_LLM_VERSION` | FATE-LLM version | v1.2.0 |
| `Platform` | Architecture types | amd64 |

The command creates the base images and then the component images. After the command finishes, all images of FATE should be created. Use `docker images` to check the newly generated images:

```bash
$ docker images | grep federatedai
REPOSITORY                           TAG  
federatedai/spark-worker-all-gpu     <TAG>
federatedai/fateflow-spark-all-gpu   <TAG>
federatedai/eggroll-all-gpu          <TAG>
federatedai/fateflow-all-gpu         <TAG>
federatedai/fate-test-ipcl           <TAG>
federatedai/spark-worker-ipcl        <TAG>
federatedai/spark-base-ipcl          <TAG>
federatedai/fateflow-spark-ipcl      <TAG>
federatedai/eggroll-ipcl             <TAG>
federatedai/fateflow-ipcl            <TAG>
federatedai/base-image-ipcl          <TAG>
federatedai/spark-worker-nn          <TAG>
federatedai/fateflow-spark-nn        <TAG>
federatedai/eggroll-nn               <TAG>
federatedai/fateflow-nn              <TAG>
federatedai/fate-upgrade-manager     <TAG>
federatedai/fate-test                <TAG>
federatedai/client                   <TAG>
federatedai/nginx                    <TAG>
federatedai/spark-worker             <TAG>
federatedai/spark-master             <TAG>
federatedai/spark-base               <TAG>
federatedai/fateflow-spark           <TAG>
federatedai/eggroll                  <TAG>
federatedai/fateboard                <TAG>
federatedai/fateflow                 <TAG>
federatedai/base-image               <TAG>
```

**all represents all algorithms (basic, NN and LLM), which can be built through Build_LLM.**
The above are all images that can be built using FATE-Builder, if you want to build all types of images, you can use the following command.

```sh
FATE_DIR=/root/FATE TAG=1.11.2-release Build_Basic=1 Build_NN=1 Build_FUM=1 Build_Spark=1 Build_OP=1 Build_IPCL=1 Build_GPU=1 Build_LLM=1 Build_LLM_VERSION=v1.2.0 IPCL_PKG_DIR=/root/pailliercryptolib_python/ IPCL_VERSION=v1.1.3 bash docker-build/build.sh all
```

### Cross-compilation function (optional)
The "Platform" field can be used to specify the processor architecture types that the built image can support, currently supporting arm64 and amd64. If this field is not specified, amd64 will be defaulted.

This function supports building images that support either arm64 or amd64 architecture under the amd64 architecture, and it also supports building images that support either arm64 or amd64 architectures under the arm64 architecture.

For example, if you want to build an arm64 image, you can use the following command.For example, if you want to build an arm64 image, you can use the following command. (The current version only supports building basic images when building images that support the arm64 architecture, that is, Build_Basic=1)

```sh
Platform=arm64 FATE_DIR=/root/FATE TAG=1.11.2-release Build_Basic=1 Build_NN=0 Build_FUM=0 Build_Spark=0 Build_OP=0 Build_IPCL=0 Build_GPU=0 Build_LLM=0 Build_LLM_VERSION=v1.2.0 IPCL_PKG_DIR=/root/pailliercryptolib_python/ IPCL_VERSION=v1.1.3 bash docker-build/build.sh all
```

### Pushing images to a registry (optional)

To share the docker images with multiple nodes, images can be pushed to a registry (such as Docker Hub or Harbor registry).

Log in to the registry first:

```bash
# for Docker Hub
$ docker login -u username 
```

or

```bash
# for Harbor or other local registry
$ docker login -u username <URL_of_Registry>
```

Next, push images to the registry. Make sure that the `PREFIX` setting in `.env` points to the correct registry service:

```bash
bash images-build/build.sh push
```

### Package the docker images for offline deployment (optional)

Some environemts may not have access to the Internet. In this case, FATE's docker images can be packaged and copied to these environments for offline deployment.

On the machine with all FATE docker images available, use the following commands to export and package images:

```bash
# Pull mysql first if you don't have those images in your machine.
$ docker pull mysql:8.0.28
$ docker save $(docker images | grep -E "mysql" | awk '{print $1":"$2}') -o third-party.images.tar.gz
$ docker save $(docker images | grep federatedai| grep -v -E "base|builder" | awk '{print $1":"$2}') -o fate.images.tar.gz
```

Two tar files should be generated `fate.images.tar.gz` and `third-party.images.tar.gz` . The formmer one contains all FATE images while the latter has the dependent third party images (mysql).

Copy the two tar files to the targeted deployment machine which is not connected to the Internet. Log in to the machine and use the following command to load the images:

```bash
docker load -i third-party.images.tar.gz
docker load -i fate.images.tar.gz
```

Now the machine has all FATE images and is ready for deployment.

### Deployment

To use docker images to deploy FATE by Docker Compose or Kubernetes, please refer to [KubeFATE](https://github.com/FederatedAI/KubeFATE) for more details.
