#!/bin/bash

# Copyright 2022 VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# you may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euxo pipefail


: "${FATE_DIR:=/data/projects/fate}"
: "${TAG:=latest}"
: "${PREFIX:=federatedai}"
: "${version_tag:=release}"
: "${Docker_Options:=""}"
: "${Build_Basic:=1}"
: "${Build_OP:=1}"
: "${Build_FUM:=0}"
: "${Build_NN:=1}"
: "${Build_Spark:=1}"
: "${Build_IPCL:=0}"
: "${IPCL_VERSION:=v1.1.3}"

BASE_DIR=$(dirname "$0")
cd $BASE_DIR
WORKING_DIR=$(pwd)

: "${PACKAGE_DIR_CACHE:=${WORKING_DIR}/cache}"

# Build and Package FATE
package() {

        mkdir -p $FATE_DIR/build/package-build/
        cp build_docker.sh $FATE_DIR/build/package-build/

        cd $FATE_DIR
        # package all

        IPCL_VERSION=$IPCL_VERSION bash $FATE_DIR/build/package-build/build_docker.sh ${version_tag} all

        rm -rf $FATE_DIR/build/package-build/build_docker.sh

        mkdir -p ${PACKAGE_DIR_CACHE}

        # FATE package_dir ${FATE_DIR}/FATE_install_${version}_release/
        cp -r ${FATE_DIR}/FATE_install_${version}_${version_tag}/* ${PACKAGE_DIR_CACHE}
}

# build_builder() {
#     echo "Building builder"
#     docker build -t federatedai/builder -f builder/Dockerfile docker/builder
#     echo "Built builder"
# }

check_fate_dir() {
    if [ ! -d "$FATE_DIR" ]; then
        echo "FATE_DIR ($FATE_DIR) does not exist"
        exit 1
    fi
}

# build_fate() {
#     echo "Building fate"
#     docker run -v $FATE_DIR:$FATE_DIR federatedai/builder /bin/bash -c "cd $FATE_DIR && ./build.sh"
#     echo "Built fate"
# }

buildBase() {
        echo "START BUILDING BASE IMAGE"
        #cd ${WORKING_DIR}
        docker build --build-arg version=${version} -f ${WORKING_DIR}/base/basic/Dockerfile \
          -t ${PREFIX}/base-image:${BASE_TAG} ${PACKAGE_DIR_CACHE}
        echo "FINISH BUILDING BASE IMAGE"
}

# build function name  build+[Component: Spark/Eggroll]+[Algorithm: Basic/NN]+[Device: CPU/IPCL]

buildEggrollBasicCPU() {
        echo "START BUILDING Eggroll Module IMAGE"

        echo "### START BUILDING fateflow ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow ###"
        echo ""
        echo "### START BUILDING fateboard ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateboard:${TAG} \
                -f ${WORKING_DIR}/modules/fateboard/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateboard ###"
        echo ""

        echo "### START BUILDING eggroll ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/eggroll:${TAG} \
                -f ${WORKING_DIR}/modules/eggroll/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING eggroll ###"
        echo ""

        echo "END BUILDING IMAGE"
}

buildSparkBasicCPU(){
        echo "START BUILDING Spark Module IMAGE"


        echo "### START BUILDING fateflow-spark ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark:${TAG} -f ${WORKING_DIR}/modules/fateflow-spark/Dockerfile ${WORKING_DIR}/modules/fateflow-spark/
        echo "### FINISH BUILDING fateflow-spark ###"
        echo ""

        echo "### START BUILDING spark-base ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-base:${TAG} -f ${WORKING_DIR}/modules/spark-base/Dockerfile ${WORKING_DIR}/modules/spark-base/
        echo "### FINISH BUILDING spark-base ###"
        echo ""

        for module in "spark-master" "spark-worker"; do
                echo "### START BUILDING ${module} ###"
                docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=spark-base --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/${module}:${TAG} -f ${WORKING_DIR}/modules/${module}/Dockerfile ${WORKING_DIR}/modules/${module}/
                echo "### FINISH BUILDING ${module} ###"
                echo ""
        done

        for module in "nginx"; do
                echo "### START BUILDING ${module} ###"
                docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/${module}:${TAG} -f ${WORKING_DIR}/modules/${module}/Dockerfile ${PACKAGE_DIR_CACHE}
                echo "### FINISH BUILDING ${module} ###"
                echo ""
        done

        echo "END BUILDING IMAGE"
}

buildEggrollNNCPU(){
        echo "### START BUILDING fateflow-nn ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-nn:${TAG} -f ${WORKING_DIR}/modules/fateflow-nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-nn ###"
        echo ""
}

buildSparkNNCPU(){
        echo "### START BUILDING fateflow-spark-nn ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-spark --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-nn:${TAG} -f ${WORKING_DIR}/modules/fateflow-nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-spark-nn ###"
        echo ""
}

buildEggrollBasicIPCL(){
        echo "### START BUILDING base-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/base-image-ipcl:${TAG} -f ${WORKING_DIR}/base/ipcl/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING base-ipcl ###"
        echo ""

        echo "### START BUILDING fateflow-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-ipcl:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-ipcl ###"
        echo ""

        echo "### START BUILDING eggroll-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/eggroll-ipcl:${TAG} \
                -f ${WORKING_DIR}/modules/eggroll/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING eggroll-ipcl ###"
        echo ""
}

buildSparkBasicIPCL(){
        echo "### START BUILDING fateflow-spark-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-ipcl:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow-spark/Dockerfile ${WORKING_DIR}/modules/fateflow-spark/
        echo "### FINISH BUILDING fateflow-spark-ipcl ###"
        echo ""

        echo "### START BUILDING spark-base-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-base-ipcl:${TAG} \
                -f ${WORKING_DIR}/modules/spark-base/Dockerfile ${WORKING_DIR}/modules/spark-base/
        echo "### FINISH BUILDING spark-base-ipcl ###"
        echo ""

        echo "### START BUILDING spark-worker-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=spark-base-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-worker-ipcl:${TAG} -f ${WORKING_DIR}/modules/spark-worker/Dockerfile ${WORKING_DIR}/modules/spark-worker/
        echo "### FINISH BUILDING spark-worker-ipcl ###"
        echo ""
}

buildFateUpgradeManager(){
        echo "START BUILDING fate-upgrade-manager"
        cp ${WORKING_DIR}/modules/fate-upgrade-manager/*.py ${PACKAGE_DIR_CACHE}
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fate-upgrade-manager:${TAG} -f ${WORKING_DIR}/modules/fate-upgrade-manager/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "FINISH BUILDING fate-upgrade-manager"
}

buildOptionalModule(){

        echo "START BUILDING Optional Module IMAGE"

        echo "### START BUILDING client ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/client:${TAG} \
                -f ${WORKING_DIR}/modules/client/Dockerfile ${WORKING_DIR}/modules/client/
        echo "### FINISH BUILDING client ###"
        echo ""

        for module in "fate-test"; do
                echo "### START BUILDING ${module} ###"
                docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/${module}:${TAG} -f ${WORKING_DIR}/modules/${module}/Dockerfile ${WORKING_DIR}/modules/${module}/
                echo "### FINISH BUILDING ${module} ###"
                echo ""
        done
        echo "END BUILDING Optional Module IMAGE"
}

buildModule(){
        # TODO selective build

        [ "$Build_Basic" -gt 0 ] && buildEggrollBasicCPU
        [ "$Build_Spark" -gt 0 ] && buildSparkBasicCPU
        [ "$Build_OP" -gt 0 ] && buildOptionalModule
        [ "$Build_FUM" -gt 0 ] && buildFateUpgradeManager
        [ "$Build_NN" -gt 0 ] && buildEggrollNNCPU
        [ "$Build_NN" -gt 0 ] && [ "$Build_IPCL" -gt 0 ] && buildSparkNNCPU
        [ "$Build_IPCL" -gt 0 ] && buildEggrollBasicIPCL
        [ "$Build_Spark" -gt 0 ] && [ "$Build_IPCL" -gt 0 ] && buildSparkBasicIPCL

}

pushImage() {
        ## push image
        for module in "fateflow" "fateboard" "eggroll" "client" "fateflow-spark" "spark-master" "spark-worker" "nginx" "fateflow-nn" "fate-test"; do
                echo "### START PUSH ${module} ###"
                docker push ${PREFIX}/${module}:${TAG}
                echo "### FINISH PUSH ${module} ###"
                echo ""
        done
}

images_push() {
    echo "Pushing images"
    for image in $(ls -d docker/modules/*/); do
        image_name=$(basename $image)
        echo "Pushing federatedai/$image_name"
        docker push federatedai/$model_name
        echo "Pushed federatedai/$image_name"
    done
    echo "Pushed images"
}

# start 

while getopts "hfpt:" opt; do
    case $opt in
        h)
            echo "Usage: ./build.sh [-h] [-f fate_dir] [-p prefix] [-t tag]"
            echo "Options:"
            echo "  -h  Show this help message and exit"
            echo "  -f  Path to fate directory"
            echo "  -p  images prefix"
            echo "  -t  images tag"
            exit 0
            ;;
        f)
            FATE_DIR=$OPTARG
            ;;
        p)
            PREFIX=$OPTARG
            ;;
        t)
            TAG=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


# check fate dir
check_fate_dir

# cd ${WORKING_DIR}
if [ -f "$FATE_DIR/fate.env" ]; then
  version="$(grep "FATE=" $FATE_DIR/fate.env | awk -F '=' '{print $2}')"
else
  echo "Error: Please set FATE_DIR or Check FATE_DIR=$FATE_DIR is a FATE directory"
  # TODO git clone FATE
  exit 1
fi

# set image PREFIX and TAG
if [  -z "${TAG}" ]; then
    TAG="${version}-release"
fi
BASE_TAG=${TAG}

if [ -f "$BASE_DIR/.env" ];then 
  source $BASE_DIR/.env
fi

# print build INFO
echo "[INFO] Build info"
echo "[INFO] Version: v"${version}
echo "[INFO] Image prefix is: "${PREFIX}
echo "[INFO] Image tag is: "${TAG}
echo "[INFO] Base image tag is: "${BASE_TAG}
echo "[INFO] Source dir: "${FATE_DIR}
echo "[INFO] Working dir: "${WORKING_DIR}
echo "[INFO] Base dir: "${BASE_DIR}
echo "[INFO] Package dir is: "${PACKAGE_DIR_CACHE}


while [ -n "${1-}" ]; do
        case $1 in
        package)
                package
                ;;
        base)
                buildBase
                ;;
        modules)
                buildModule
                ;;
        all)
                package
                buildBase
                buildModule
                ;;
        push)
                pushImage
                ;;
        *)
                echo "Usage: bash build.sh [Options] [package|base|modules|all|push]"
        esac
        shift
done