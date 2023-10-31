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
: "${Build_GPU:=0}"
: "${Build_LLM:=0}"
: "${Build_LLM_VERSION:=v1.2.0}"

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

        Build_IPCL=$Build_IPCL IPCL_VERSION=$IPCL_VERSION bash $FATE_DIR/build/package-build/build_docker.sh ${version_tag} all

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
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-base:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow/Dockerfile ${PACKAGE_DIR_CACHE}
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-base --build-arg BASE_TAG=${TAG} ${Docker_Options} -t ${PREFIX}/fateflow:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow-eggroll/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow ###"
        echo ""
        echo "### START BUILDING osx ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/osx:${TAG} \
                -f ${WORKING_DIR}/modules/osx/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING osx ###"
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
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark:${TAG} -f ${WORKING_DIR}/modules/fateflow-spark/Dockerfile ${WORKING_DIR}/modules/fateflow-spark/
        echo "### FINISH BUILDING fateflow-spark ###"
        echo ""

        echo "### START BUILDING spark-base ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-spark --build-arg BASE_TAG=${TAG} ${Docker_Options} -t ${PREFIX}/spark-base:${TAG} -f ${WORKING_DIR}/modules/spark-base/Dockerfile ${WORKING_DIR}/modules/spark-base/
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
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-nn:${TAG} \
                -f ${WORKING_DIR}/modules/nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-nn ###"
        echo ""

        echo "### START BUILDING eggroll-nn ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=eggroll --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/eggroll-nn:${TAG} \
                -f ${WORKING_DIR}/modules/nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING eggroll-nn ###"
        echo ""

}


buildSparkNNCPU(){
        echo "### START BUILDING fateflow-spark-nn ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-spark --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-nn:${TAG} \
                -f ${WORKING_DIR}/modules/nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-spark-nn ###"
        echo ""

        echo "### START BUILDING spark-worker-nn ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=spark-worker --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-worker-nn:${TAG} \
                -f ${WORKING_DIR}/modules/nn/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING spark-worker-nn ###"
        echo ""

}


buildEggrollNNGPU(){
        echo "### START BUILDING fateflow-nn-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-nn-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/gpu/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-nn-gpu ###"
        echo ""

        echo "### START BUILDING eggroll-nn-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=eggroll --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/eggroll-nn-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/gpu/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING eggroll-nn-gpu ###"
        echo ""

}


buildSparkNNGPU(){
        echo "### START BUILDING fateflow-spark-nn-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-spark --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-nn-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/gpu/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-spark-nn-gpu ###"
        echo ""

        echo "### START BUILDING spark-worker-nn-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=spark-worker --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-worker-nn-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/gpu/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING spark-worker-nn-gpu ###"
        echo ""

}


buildEggrollAllGPU(){
        echo "### START BUILDING fateflow-all-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-nn-gpu --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-all-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/fate-llm/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-all-gpu ###"
        echo ""

        echo "### START BUILDING eggroll-all-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=eggroll-nn-gpu --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/eggroll-all-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/fate-llm/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING eggroll-all-gpu ###"
        echo ""

}


buildSparkAllGPU(){
        echo "### START BUILDING fateflow-spark-all-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-spark-nn-gpu --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-all-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/fate-llm/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING fateflow-spark-all-gpu ###"
        echo ""

        echo "### START BUILDING spark-worker-all-gpu ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=spark-worker-nn-gpu --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/spark-worker-all-gpu:${TAG} \
                -f ${WORKING_DIR}/modules/fate-llm/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING spark-worker-all-gpu ###"
        echo ""

}


buildEggrollBasicIPCL(){
        echo "### START BUILDING base-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/base-image-ipcl:${TAG} -f ${WORKING_DIR}/base/ipcl/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "### FINISH BUILDING base-ipcl ###"
        echo ""

        echo "### START BUILDING fateflow-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=base-image-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fateflow-ipcl-base:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow/Dockerfile ${PACKAGE_DIR_CACHE}
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-ipcl-base --build-arg BASE_TAG=${TAG} ${Docker_Options} -t ${PREFIX}/fateflow-ipcl:${TAG} \
                -f ${WORKING_DIR}/modules/fateflow-eggroll/Dockerfile ${PACKAGE_DIR_CACHE}
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
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-ipcl-base --build-arg BASE_TAG=${TAG} ${Docker_Options} -t ${PREFIX}/fateflow-spark-ipcl:${TAG} \
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

buildOptionalModule(){

        echo "START BUILDING Optional Module IMAGE"

        echo "### START BUILDING client ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/client:${TAG} \
                -f ${WORKING_DIR}/modules/client/Dockerfile ${WORKING_DIR}/modules/client/
        echo "### FINISH BUILDING client ###"
        echo ""

        echo "### START BUILDING fate-test ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=client --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fate-test:${TAG} -f ${WORKING_DIR}/modules/fate-test/Dockerfile ${WORKING_DIR}/modules/fate-test/
        echo "### FINISH BUILDING fate-test ###"
        echo ""

        echo "END BUILDING Optional Module IMAGE"
}

buildOptionalIPCLModule(){

        echo "START BUILDING Optional Module IMAGE"
        
        echo "### START BUILDING fate-test-ipcl ###"
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_IMAGE=fateflow-ipcl --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fate-test-ipcl:${TAG} -f ${WORKING_DIR}/modules/fate-test/Dockerfile ${WORKING_DIR}/modules/fate-test/
        echo "### FINISH BUILDING fate-test-ipcl ###"
        echo ""

        echo "END BUILDING Optional Module IMAGE"
}

buildFateUpgradeManager(){
        echo "START BUILDING fate-upgrade-manager"
        cp ${WORKING_DIR}/modules/fate-upgrade-manager/*.py ${PACKAGE_DIR_CACHE}
        docker build --build-arg PREFIX=${PREFIX} --build-arg BASE_TAG=${BASE_TAG} ${Docker_Options} -t ${PREFIX}/fate-upgrade-manager:${TAG} -f ${WORKING_DIR}/modules/fate-upgrade-manager/Dockerfile ${PACKAGE_DIR_CACHE}
        echo "FINISH BUILDING fate-upgrade-manager"
}

buildModule(){
        # TODO selective build

        [ "$Build_Basic" -gt 0 ] && buildEggrollBasicCPU
        [ "$Build_Spark" -gt 0 ] && buildSparkBasicCPU
        
        [ "$Build_NN" -gt 0 ] && buildEggrollNNCPU
        [ "$Build_Spark" -gt 0 ] && [ "$Build_NN" -gt 0 ] && buildSparkNNCPU
        
        [ "$Build_NN" -gt 0 ] && [ "$Build_GPU" -gt 0 ] && buildEggrollNNGPU
        [ "$Build_Spark" -gt 0 ] && [ "$Build_NN" -gt 0 ] && [ "$Build_GPU" -gt 0 ] && buildSparkNNGPU
        
        [ "$Build_LLM" -gt 0 ] && [ "$Build_GPU" -gt 0 ] && buildEggrollAllGPU
        [ "$Build_Spark" -gt 0 ] && [ "$Build_LLM" -gt 0 ] && [ "$Build_GPU" -gt 0 ] && buildSparkAllGPU

        
        [ "$Build_IPCL" -gt 0 ] && buildEggrollBasicIPCL
        [ "$Build_IPCL" -gt 0 ] && [ "$Build_Spark" -gt 0 ] && buildSparkBasicIPCL

        [ "$Build_OP" -gt 0 ] && buildOptionalModule
        [ "$Build_OP" -gt 0 ] && [ "$Build_IPCL" -gt 0 ] && buildOptionalIPCLModule
        
        [ "$Build_FUM" -gt 0 ] && buildFateUpgradeManager
}

pushImage() {
        ## push EggRoll image (EggRoll Basic CPU)
        if [ "$Build_Basic" -gt 0 ]
        then
                for module in "fateflow" "osx" "eggroll" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        ## push Spark image (Spark Basic CPU)
        if [ "$Build_Spark" -gt 0 ]
        then
                for module in "fateflow-spark" "spark-master" "spark-worker" "nginx" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        ## push EggRoll nn image (EggRoll NN CPU)
        if [ "$Build_NN" -gt 0 ]
        then
                for module in "fateflow-nn" "eggroll-nn" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi
        ## push Spark nn image (Spark NN CPU)
        if [ "$Build_Spark" -gt 0 ] && [ "$Build_NN" -gt 0 ]
        then
                for module in "fateflow-spark-nn" "spark-worker-nn" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi


        ## push EggRoll nn-gpu image (EggRoll NN GPU)
        if [ "$Build_NN" -gt 0 ] && [ "$Build_GPU" -gt 0 ]
        then
                for module in "fateflow-nn-gpu" "eggroll-nn-gpu" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi
        ## push Spark nn-gpu image (Spark NN GPU)
        if [ "$Build_Spark" -gt 0 ] && [ "$Build_NN" -gt 0 ] && [ "$Build_GPU" -gt 0 ]
        then
                for module in "fateflow-spark-nn-gpu" "spark-worker-nn-gpu" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi


        ## push LLM image (EggRoll ALL GPU)
        if [ "$Build_LLM" -gt 0 ] && [ "$Build_GPU" -gt 0 ]
        then
                for module in "eggroll-all-gpu" "fateflow-all-gpu" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi
        ## push Spark LLM image (Spark ALL GPU)
        if [ "$Build_Spark" -gt 0 ] && [ "$Build_LLM" -gt 0 ] && [ "$Build_GPU" -gt 0 ]
        then
                for module in "fateflow-spark-all-gpu" "spark-worker-all-gpu" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi


        ## push IPCL image
        if [ "$Build_IPCL" -gt 0 ]
        then
                for module in "fateflow-ipcl" "eggroll-ipcl" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        if [ "$Build_IPCL" -gt 0 ] && [ "$Build_Spark" -gt 0 ]
        then
                for module in "spark-worker-ipcl" "fateflow-spark-ipcl" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        ## push OP image
        if [ "$Build_OP" -gt 0 ]
        then
                for module in "client" "fate-test" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        ## push IPCL OP image
        if [ "$Build_IPCL" -gt 0 ] && [ "$Build_OP" -gt 0 ]
        then
                for module in "fate-test-ipcl"; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi

        ## push FUM image
        if [ "$Build_FUM" -gt 0 ]
        then
                for module in "fate-upgrade-manager" ; do
                        echo "### START PUSH ${module} ###"
                        docker push ${PREFIX}/${module}:${TAG}
                        echo "### FINISH PUSH ${module} ###"
                        echo ""
                done
        fi
        
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

check_fate_dir() {
    if [ ! -d "$FATE_DIR" ]; then
        echo "FATE_DIR ($FATE_DIR) does not exist"
        exit 1
    fi
}

# check fate dir
check_fate_dir

# cd ${WORKING_DIR}
version="$(cd "$FATE_DIR"; git describe --tags --abbrev=0)"

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