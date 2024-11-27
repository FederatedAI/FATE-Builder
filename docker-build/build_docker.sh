#!/bin/bash
#
#  Copyright 2019 The FATE Authors. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

set -euxo
source_dir=$(
    cd "$(dirname "$0")"
    cd ../
    cd ../
    pwd
)
support_modules=(bin examples deploy proxy fate fate_flow fate_client fate_test osx eggroll doc fate_board)

[ "${Build_IPCL:-0}" -gt 0 ] && support_modules[${#support_modules[@]}]=ipcl_pkg
# environment_modules=(python36 jdk pypi)
packaging_modules=()
echo "${source_dir}"
if [[ -n ${1} ]]; then
    version_tag=$1
else
    version_tag="rc"
fi

cd "${source_dir}"
echo "[INFO] source dir: ${source_dir}"
#git submodule init
#git submodule update
#version=$(git describe --tags --abbrev=0)
version="v2.2.0"
package_dir_name="FATE_install_${version}_${version_tag}"
package_dir=${source_dir}/${package_dir_name}
echo "[INFO] build info"
echo "[INFO] version: ""${version}"
echo "[INFO] version tag: ""${version_tag}"
echo "[INFO] package output dir is ""${package_dir}"
rm -rf "${package_dir}" "${package_dir}"".tar.gz"
mkdir -p "${package_dir}"

function packaging_bin() {
    packaging_general_dir "bin"
    cp RELEASE.md python/requirements*.txt "${package_dir}"/
}

function packaging_examples() {
    packaging_general_dir "examples"
}

function packaging_deploy() {
    packaging_general_dir "deploy"
}

function packaging_doc() {
    packaging_general_dir "doc"
}

function packaging_general_dir() {
    dir_name=$1
    echo "[INFO] package ${dir_name} start"
    if [[ -d "${package_dir}/${dir_name}" ]]; then
        rm -rf "${package_dir:?}/${dir_name:?}"
    fi
    cp -r "${dir_name}" "${package_dir}"/
    echo "[INFO] package ${dir_name} done"
}

function packaging_fate() {
    echo "[INFO] package fate start"
    if [[ -d "${package_dir}/fate" ]]; then
        rm -rf "${package_dir}"/fate
    fi
    mkdir -p "${package_dir}"/fate
    cp -r python "${package_dir}"/fate/
    echo "[INFO] package fate done"
}

function packaging_fate_flow() {
    echo "[INFO] package fate_flow start"
    cp -r fate_flow "${package_dir}"/fate_flow
    echo "[INFO] package fate_flow done"
}

function packaging_fate_test() {
    echo "[INFO] package fate_test start"
    cp -r fate_test "${package_dir}"/fate_test
    echo "[INFO] package fate_test done"
}

function packaging_osx() {
    echo "[INFO] package osx start"
    cp -r java/osx "${package_dir}"/osx
    echo "[INFO] package osx done"
}
packaging_fate_board() {
	        echo "[INFO] package fateboard start"
	        #pull_fateboard
		      cd  ./fate_board
			    mvn -DskipTests -f "${source_dir}/fate_board/pom.xml" -q clean package

          rm -rf "${package_dir}"/fateboard
          mkdir -p "${package_dir}"/fateboard

          cp -ap "${source_dir}"/fate_board/RELEASE.md "${package_dir}"/fateboard
          unzip "${source_dir}"/target/fateboard-*-release.zip -d "${package_dir}"/fateboard
          ln -frs "${package_dir}"/fateboard/fateboard-*.jar "${package_dir}"/fateboard/fateboard.jar
			    cd "${package_dir}"
			    mv fateboard fate_board
					echo "[INFO] package fateboard done"
}
packaging_fate_client() {
    echo "[INFO] package fate_client start"
    cp -r fate_client "${package_dir}"/
    echo "[INFO] package fate_client done"
}

packaging_eggroll() {
    echo "[INFO] package eggroll start"
    cd ./eggroll
    cd ./deploy
    docker run --rm -u "$(id -u):$(id -g)" -v "${source_dir}/eggroll:/data/projects/fate/eggroll" --entrypoint="" maven:3.8-jdk-8 /bin/bash -c "cd /data/projects/fate/eggroll/deploy && bash auto-packaging.sh"
    mkdir -p "${package_dir}"/eggroll
    mv "${source_dir}"/eggroll/eggroll.tar.gz "${package_dir}"/eggroll/
    echo "package_dir:_____________________${package_dir}"
    cd "${package_dir}"/eggroll/
    tar xzf eggroll.tar.gz
    rm -rf eggroll.tar.gz
    echo "${source_dir}/eggroll/requirements.txt"
    cp "${source_dir}"/eggroll/requirements.txt ./
    echo "[INFO] package eggroll done"
}

packaging_ipcl_pkg(){
    echo "[INFO] package ipcl_pkg start"
    #IPCL_PKG_DIR = "/data/projects/llm/fate/pailliercryptolib_python"
    echo "IPCL_PKG_DIR= ${IPCL_PKG_DIR}"
    if [[ ! -d ${IPCL_PKG_DIR} ]] 
    then
        git clone --single-branch -b "${IPCL_VERSION}"  https://github.com/intel/pailliercryptolib_python "${IPCL_PKG_DIR}"
    fi
    mkdir -p "${package_dir}"/ipcl_pkg
    cp -r "${IPCL_PKG_DIR}"/* "${package_dir}"/ipcl_pkg/

    echo "[INFO] package ipcl_pkg done"
}


function pull_fate_llm() {
echo "[INFO] get fate_llm code start"
    cd "${source_dir}"
    fate_llm_git_url="https://github.com/FederatedAI/FATE-LLM.git"
    fate_llm_git_branch="${Build_LLM_VERSION:-v1.2.0}"
    echo "[INFO] git clone fate_llm source code from ${fate_llm_git_url} branch ${fate_llm_git_branch}"
    if [[ -d "fate_llm" ]]; then
        while 'true' ; do
            read -r -p "the fate_llm directory already exists, delete and re-download? [y/n] " input
            case ${input} in
            [yY]*)
                echo "[INFO] delete the original fate_llm"
                rm -rf fate_llm
                git clone ${fate_llm_git_url} -b "${fate_llm_git_branch}" --depth=1 fate_llm
                break
                ;;
            [nN]*)
                echo "[INFO] use the original fate_llm"
                break
                ;;
            *)
                echo "just enter y or n, please."
                ;;
            esac
        done
    else
        git clone ${fate_llm_git_url} -b "${fate_llm_git_branch}" --depth=1 fate_llm
    fi
    echo "[INFO] get fate_llm code done"
}

function packaging_fate_llm() {
    echo "[INFO] package FATE-LLM start"
    pull_fate_llm
    cp -r fate_llm "${package_dir}"/
    echo "[INFO] package FATE-LLM done"
}

function packaging_proxy() {
    echo "[INFO] package proxy start"
    cd c/proxy
    mkdir -p "${package_dir}"/proxy/nginx
    cp -r conf lua "${package_dir}"/proxy/nginx/
    echo "[INFO] package proxy done"
}

compress() {
    echo "[INFO] compress start"
    cd "${package_dir}"
    touch ./packages_md5.txt
    os_kernel=$(uname -s)
    find ./ -name ".*" | grep "DS_Store" | xargs -n1 rm -rf
    find ./ -name ".*" | grep "pytest_cache" | xargs -n1 rm -rf
    for module in "${packaging_modules[@]}";
    do
        case "${os_kernel}" in
            Darwin)
                gtar czf "${module}".tar.gz ./"${module}"
                md5_value=$(md5 "${module}".tar.gz | awk '{print $4}')
                ;;
            Linux)
                tar czf "${module}".tar.gz ./"${module}"
                md5_value=$(md5sum "${module}".tar.gz | awk '{print $1}')
                ;;
        esac
        echo "${module}:${md5_value}" >>./packages_md5.txt
        rm -rf ./"${module}"
    done
    echo "[INFO] compress done"
    echo "[INFO] a total of $(find "${package_dir}" | wc -l | awk '{print $1}') packages:"
    ls -lrt "${package_dir}"
    package_dir_parent=$(
        cd "$(dirname "${package_dir}")"
        pwd
    )
    cd "${package_dir_parent}"
    tar czf "${package_dir_name}"".tar.gz" "${package_dir_name}"
}

build() {
    echo "[INFO] packaging start------------------------------------------------------------------------"
    for module in "${packaging_modules[@]}"; do
        cd "${source_dir}"
        packaging_"${module}"
        echo
    done
    echo "[INFO] packaging end ------------------------------------------------------------------------"
    compress
}

all() {
    for ((i = 0; i < ${#support_modules[*]}; i++)); do
        packaging_modules[i]=${support_modules[i]}
    done
    build
}

multiple() {
    total=$#
    for ((i = 2; i < total + 1; i++)); do
        packaging_modules[i]=${!i//\//}
    done
    build
}

usage() {
    echo "usage: $0 {version_tag} {all|[module1, ...]}"
}

case "$2" in
all)
    all "$@"
    ;;
usage)
    usage
    ;;
*)
    multiple "$@"
    ;;
esac
