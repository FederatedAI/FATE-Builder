#!/usr/bin/env bash

set -euxo pipefail
shopt -s expand_aliases extglob

: "${FATE_DIR:=/data/projects/fate}"
: "${CLON_GIT:=0}"
: "${PULL_GIT:=0}"
: "${PULL_OPT:=--rebase --stat --autostash}"
: "${CHEC_BRA:=0}"
: "${SKIP_BUI:=0}"
: "${COPY_ONL:=0}"
: "${BUIL_PYP:=1}"
: "${BUIL_EGG:=1}"
: "${BUIL_BOA:=1}"
: "${BUIL_FAT:=1}"
: "${SKIP_PKG:=0}"
: "${PATH_CON:=cos://fate/resources/Miniconda3-py38_4.12.0-Linux-x86_64.sh}"
: "${PATH_JDK:=cos://fate/resources/jdk-8u345.tar.xz}"
: "${PATH_MYS:=cos://fate/resources/mysql-8.0.28.tar.gz}"
: "${PATH_RMQ:=cos://fate/resources/rabbitmq-server-generic-unix-3.9.14.tar.xz}"
: "${PATH_SVR:=cos://fate/resources/supervisor-4.2.4-py2.py3-none-any.whl}"
: "${PATH_PYM:=cos://fate/resources/PyMySQL-1.0.2-py3-none-any.whl}"
: "${PATH_WBE:=cos://fate/resources/wb-info-enc-1.0-SNAPSHOT.jar}"
: "${SYNC_RES:=1}"
: "${RELE_VER:=release}"
: "${PACK_ARC:=0}"
: "${PACK_PYP:=0}"
: "${PACK_STA:=0}"
: "${PACK_DOC:=0}"
: "${PACK_CLU:=0}"
: "${PACK_OFF:=0}"
: "${PACK_ONL:=0}"
: "${PUSH_ARC:=0}"

commands=( 'date' 'dirname' 'readlink' 'mkdir' 'printf' 'cp' 'ln' 'grep'
           'xargs' 'chmod' 'rm' 'awk' 'find' 'tar' 'sed' 'md5sum')
tools=( 'git' 'mvn' 'npm' 'docker' )
modules=( 'fate' 'fateflow' 'fateboard' 'eggroll' )

case "$OSTYPE" in
    linux*)  plat='linux' ;;
    darwin*) plat='mac'   ;;
    *)       exit 1       ;;
esac

if [ "$plat" == 'mac' ]
then
    for command in "${commands[@]}"
    {
        type "g$command" >/dev/null
    }
else
    for command in "${commands[@]}"
    {
        eval "function g$command { $command \"\$@\"; }"
        declare -fx "g$command"
    }
fi

for tool in "${tools[@]}"
{
    type "$tool" >/dev/null
}

trap 'echo $?' EXIT

start=$(gdate +%s%N)
PS4='+ [$(bc <<< "scale=3; x=($(gdate +%s%N) - $start) / 1000 / 1000 / 1000; if (x < 1) \"0\"; x")s \
$BASHPID ${BASH_SOURCE}:${LINENO}${FUNCNAME:+ $BASH_LINENO:${FUNCNAME}}] '

dir="$(gdirname "$(greadlink -f "${BASH_SOURCE[0]}")")"
[ -f "$dir/.env" ] && . "$dir/.env"

FATE_DIR="$(greadlink -f "$FATE_DIR")"

alias _git="git -C '$FATE_DIR'"
_git status >/dev/null

alias coscli="'$dir/bin/coscli-$plat' -c '$dir/cos.yaml'"
# coscli ls 'cos://fate' >/dev/null

function git_pull
{
    _git pull $PULL_OPT
    _git submodule foreach --recursive 'git -C "$toplevel/$sm_path" pull '"$PULL_OPT"
}

function get_versions
{
    declare -gA versions

    for module in "${modules[@]}"
    {
        versions[$module]="$(ggrep -ioP "(?<=$module=).+" "$FATE_DIR/fate.env")"
    }
}

function check_branch
{
    for key in "${!versions[@]}"
    {
        readarray -t ver <<< "$(git -C "$FATE_DIR/${key%fate}" branch --show-current | ggrep -oP '\d+')"
        [ "${#ver[@]}" -eq 2 ] && ver+=( 0 )

        printf -v ver '%s.' "${ver[@]}"
        ver="${ver:0:-1}"

        [ "$ver" == "${versions[$key]}" ] || return 1
    }
}

function build_eggroll
{
    local source="$FATE_DIR/eggroll"
    local target="$dir/build/$FATE_VER/eggroll"

    [ "$COPY_ONL" -gt 0 ] || mvn -DskipTests -f "$source/jvm/pom.xml" -q clean package

    grm -rf "$target"
    gmkdir -p "$target/lib"

    for module in 'core' 'roll_pair' 'roll_site'
    {
        gcp -af "$source/jvm/$module/target/eggroll-"${module//_/-}"-${versions[eggroll]}.jar" \
                "$source/jvm/$module/target/lib/"*.jar \
                "$target/lib"
    }
    gcp -af "${resources[wbenc]}" "$target/lib"

    gcp -af "$source/"{BUILD_INFO,bin,conf,data,deploy,python} "$target"
    gcp -af "$source/jvm/core/main/resources/"*.sql "$target/conf"
}

function build_fateboard
{
    local source="$FATE_DIR/fateboard"
    local target="$dir/build/$FATE_VER/fateboard"

    [ "$COPY_ONL" -gt 0 ] ||
    {
        mvn -DskipTests -f "$source/pom.xml" -q clean package
    }

    grm -rf "$target"
    gmkdir -p "$target/conf"

    gcp -af "$source/src/main/resources/application.properties" "$target/conf"
    gcp -af "$source/target/fateboard-${versions[fateboard]}.jar" \
            "$source/bin/service.sh" \
            "$source/RELEASE.md" \
            "$target"

    gln -frs "$target/fateboard-${versions[fateboard]}.jar" "$target/fateboard.jar"
}

function build_python_packages
{
    local source="$FATE_DIR/python/requirements.txt"
    local target="$dir/build/$FATE_VER/pypkg"

    grm -rf "$target"
    gmkdir -p "$target"

    os_plat=`arch`
    if [ $os_plat == "x86_64" ];then
    docker run --pull=always --rm \
        -v "$(greadlink -f ~/.config/pip/pip.conf):/root/.config/pip/pip.conf:ro" \
        -v "$source:/requirements.txt:ro" -v "$target:/wheelhouse:rw" \
        quay.io/pypa/manylinux2014_x86_64:latest /bin/bash -c '

        sed -e "s!^mirrorlist=!#mirrorlist=!g" -e "s!^#baseurl=!baseurl=!g" \
        -e "s!http://mirror\.centos\.org!https://mirrors.cloud.tencent.com!g" \
        -i /etc/yum.repos.d/CentOS-*.repo && \

        sed -e "s!^metalink=!#metalink=!g" -e "s!^#baseurl=!baseurl=!g" \
        -e "s!http://download\.example/pub!https://mirrors.cloud.tencent.com!g" \
        -i /etc/yum.repos.d/epel*.repo && \

        yum install -q -y gmp-devel mpfr-devel libmpc-devel && \
        /opt/python/cp38-cp38/bin/pip wheel -q -r /requirements.txt -w /wheelhouse || \
        exit 1

        for whl in /wheelhouse/*.whl
        {
            auditwheel show "$whl" &>/dev/null &&
            {
                new_whl=$(auditwheel repair --plat manylinux2014_x86_64 -w /wheelhouse "$whl" 2>&1 | \
                          grep -ioP "(?<=Fixed-up wheel written to ).+\.whl")
                [ -n "$new_whl" ] && [ "$new_whl" != "$whl" ] && rm -f "$whl"
            }
        }
        :'
    elif [ $os_plat == "aarch64" ];then
    docker run --rm \
        -v "$(greadlink -f ~/.config/pip/pip.conf):/root/.config/pip/pip.conf:ro" \
        -v "$source:/requirements.txt:ro" -v "$target:/wheelhouse:rw" \
        vowpalwabbit/manylinux2014_aarch64-build:latest /bin/bash -c '
        cp /requirements.txt /opt/requirements.txt && \

        sed -e "s!tensorflow-cpu==2.11.1!tensorflow==2.10.0!g" -e "s!torch==1.13.1+cpu!torch==1.13.1!g" \
        -e "s!torchvision==0.14.1+cpu!torchvision==0.14.1!g" \
        -e "s!numba==0.53.0!numba==0.57.0!g" \
        -e "s!ipcl-python==2.0.0!#ipcl-python==2.0.0!g" \
        -i /opt/requirements.txt && cat /opt/requirements.txt && \

        sed -i "57a h5py==3.10.0" /opt/requirements.txt && \

        yum install  -y gmp-devel mpfr-devel libmpc-devel && \
        /opt/python/cp38-cp38/bin/pip wheel -q -r /opt/requirements.txt -w /wheelhouse || \
        exit 1

        for whl in /wheelhouse/*.whl
        {
            auditwheel show "$whl" &>/dev/null &&
            {
                new_whl=$(auditwheel repair --plat manylinux2014_aarch64 -w /wheelhouse "$whl" 2>&1 | \
                          grep -ioP "(?<=Fixed-up wheel written to ).+\.whl")
                [ -n "$new_whl" ] && [ "$new_whl" != "$whl" ] && rm -f "$whl"
            }
        }
        :'
    fi

    sudo chown "$(id -u):$(id -g)" "$target/"*
}

function build_fate
{
    grm -rf "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fateflow"
    gmkdir -p "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fateflow"

    gcp -af "$FATE_DIR/"{RELEASE.md,fate.env,bin,deploy,examples,python} "$dir/build/$FATE_VER/fate"
    gcp -af "$FATE_DIR/fateflow/"{RELEASE.md,bin,conf,examples,python} "$dir/build/$FATE_VER/fateflow"

    gmkdir -p "$dir/build/$FATE_VER/fate/conf" "$dir/build/$FATE_VER/fate/proxy"
    gcp -af "$FATE_DIR/conf/"!(local.*).yaml "$dir/build/$FATE_VER/fate/conf"
    gcp -af "$FATE_DIR/c/proxy" "$dir/build/$FATE_VER/fate/proxy/nginx"

    gsed -i '/--extra-index-url/d' "$dir/build/$FATE_VER/fate/python/requirements.txt"
}

function build_cleanup
{
    gfind "$dir/build/$FATE_VER" -type d -print0 | parallel -0Xj1 gchmod 755
    gfind "$dir/build/$FATE_VER" -type f -print0 | parallel -0Xj1 gchmod 644

    gfind "$dir/build/$FATE_VER" -iname '*.sh' -print0 | parallel -0Xj1 gchmod a+x

    gfind "$dir/build/$FATE_VER" -iname '__pycache__' -prune -print0 | parallel -0Xj1 grm -fr
    gfind "$dir/build/$FATE_VER" -iname '*.pyc' -print0 | parallel -0Xj1 grm -f
}

function get_resources
{
    declare -gA resources=(
        [conda]="$PATH_CON"
        [jdk]="$PATH_JDK"
        [mysql]="$PATH_MYS"
        [rabbitmq]="$PATH_RMQ"
        [supervisor]="$PATH_SVR"
        [pymysql]="$PATH_PYM"
        [wbenc]="$PATH_WBE"
    )

    gmkdir -p "$dir/resources"

    for key in "${!resources[@]}"
    {
        [ "$SYNC_RES" -gt 0 ] && coscli sync "${resources[$key]}" "$dir/resources"

        resources[$key]="$dir/resources/${resources[$key]##*/}"
    }

    chmod 644 "$dir/resources/"*
    chmod 755 "$dir/resources/"*.sh
}

function push_archive
{
    [ "$PUSH_ARC" -gt 0 ] || return 0

    coscli sync "$filepath" "cos://fate/fate/$FATE_VER/$RELE_VER/${filepath##*/}"
    # coscli sync "cos://fate/fate/$FATE_VER/$RELE_VER/${filepath##*/}" "cos://fate/${filepath##*/}"
}

function package_fate_install
{
    local source="$dir/build/$FATE_VER/fate"
    local name="fate_install_${FATE_VER}_${RELE_VER}"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    grm -fr "$target"
    gmkdir -p "$target"

    for module in 'eggroll' 'fateboard' 'fateflow'
    {
        gtar -cpz -f "$target/$module.tar.gz" -C "$dir/build/$FATE_VER" "$module"
    }

    gfind "$source" -mindepth 1 -maxdepth 1 -type d -not -iname 'python' -print0 | \
        parallel -0 gtar -cpz -f "$target/{/}.tar.gz" -C "$source" '{/}'
    gtar -cpz -f "$target/fate.tar.gz" -C "$source" --transform 's#^python#fate/python#' 'python'

    gmd5sum "$target/"*.tar.gz | gawk '{ sub(/\/.+\//, ""); sub(/\.tar\.gz/, ""); print $2 ":" $1 }' \
        >"$target/packages_md5.txt"

    gfind "$source" -mindepth 1 -maxdepth 1 -type f -print0 | \
        parallel -0Xj1 gcp -af '{}' "$target"
    gcp -af "$source/python/requirements.txt" "$target"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_python_packages
{
    local name="pip_packages_fate_${FATE_VER}"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    gtar -cpz -f "$filepath" -C "$dir/build/$FATE_VER" --transform "s/^pypkg/$name/" 'pypkg'
    filepath="$filepath" push_archive
}

function package_standalone
{
    local source="$dir/templates/standalone_fate"

    grm -fr "$target"
    gmkdir -p "$target/fate"

    gcp -af "$dir/build/$FATE_VER/fate/"!(python*|proxy*) "$dir/build/$FATE_VER/"{fateboard,fateflow} "$target"
    gcp -af  "$dir/build/$FATE_VER/fate/python" "$target/fate"
    gln -frs "$target/fate/python/requirements.txt" "$target/requirements.txt"

    gcp -af "$source/"*.sh "$target/bin"
    gcp -af "$source/"!(*.sh) "$target"

    gmkdir -p "$target/env/"{jdk,python}
    gcp -af "${resources[jdk]}" "$target/env/jdk"
    gcp -af "${resources[conda]}" "$target/env/python"

    gcp -af "$dir/build/$FATE_VER/pypkg" "$target/env/pypi"
}

function package_standalone_install
{
    local name="standalone_fate_install_${FATE_VER}_${RELE_VER}"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    target="$target" package_standalone

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_standalone_docker
{
    local name="standalone_fate_docker_image_${FATE_VER}_${RELE_VER}"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    local image_hub="federatedai/standalone_fate"
    local image_tcr="ccr.ccs.tencentyun.com/federatedai/standalone_fate"

    local image_tag="$FATE_VER"
    [ "$RELE_VER" == 'release' ] || image_tag+="-$RELE_VER"

    target="$target" package_standalone

    docker buildx build --compress --progress=plain --pull --rm \
        --file "$target/Dockerfile" --tag "$image_hub:$image_tag" "$target"

    docker save "$image_hub:$image_tag" | gzip > "$filepath"
    filepath="$filepath" push_archive

    docker tag "$image_hub:$image_tag" "$image_tcr:$image_tag"

    [ "$PUSH_ARC" -gt 0 ] || return 0
    docker push "$image_tcr:$image_tag"
}

function package_cluster_install
{
    local source="$dir/templates/fate_cluster_install"
    local name="fate_cluster_install_${FATE_VER}_${RELE_VER}"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/$FATE_VER/" "$target/allInone/conf/setup.conf"

    gmkdir -p "$target/python-install/files"
    gcp -af "${resources[conda]}" "$dir/build/$FATE_VER/fate/python/requirements.txt" "$dir/build/$FATE_VER/pypkg" "$target/python-install/files"

    gmkdir -p "$target/java-install/files"
    gcp -af "${resources[jdk]}" "$target/java-install/files"

    gmkdir -p "$target/mysql-install/files"
    gcp -af "${resources[mysql]}" "$dir/build/$FATE_VER/eggroll/conf/create-eggroll-meta-tables.sql" "$target/mysql-install/files"

    gmkdir -p "$target/eggroll-install/files"
    gcp -af "$dir/build/$FATE_VER/eggroll" "$target/eggroll-install/files"

    gmkdir -p "$target/fate-install/files"
    gcp -af "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fateflow" "$dir/build/$FATE_VER/fateboard" "$target/fate-install/files"

    gmkdir -p "$target/allInone/logs"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_ansible
{
    local source="$dir/templates/AnsibleFATE"

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/$FATE_VER/" "$target/deploy/files/fate_init"

    gmkdir -p "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate/python/requirements.txt" "$target/roles/python/files"
    [ "$include_large_files" -gt 0 ] &&
    {
        gcp -af "${resources[conda]}" "$target/roles/python/files"
        gtar -cpz -f "$target/roles/python/files/pypi.tar.gz" -C "$dir/build/$FATE_VER" --transform "s/^pypkg/pypi/" 'pypkg'
    }

    gmkdir -p "$target/roles/java/files"
    [ "$include_large_files" -gt 0 ] && \
        gcp -af "${resources[jdk]}" "$target/roles/java/files"

    gmkdir -p "$target/roles/mysql/files"
    [ "$include_large_files" -gt 0 ] && \
        gcp -af "${resources[mysql]}" "$target/roles/mysql/files"

    gmkdir -p "$target/roles/rabbitmq/files"
    [ "$include_large_files" -gt 0 ] && \
        gcp -af "${resources[rabbitmq]}" "$target/roles/rabbitmq/files"

    gmkdir -p "$target/roles/supervisor/files"
    gln -frs "$target/roles/python/files/${resources[conda]##*/}" "$target/roles/supervisor/files"
    gcp -af "${resources[supervisor]}" "${resources[pymysql]}" "$target/roles/supervisor/files"

    gtar -cpz -f "$target/roles/check/files/deploy.tar.gz" -C "$dir/build/$FATE_VER/fate" 'deploy'

    gmkdir -p "$target/roles/eggroll/files"
    gcp -af "$dir/build/$FATE_VER/eggroll/conf/create-eggroll-meta-tables.sql" "$target/roles/eggroll/files"
    gtar -cpz -f "$target/roles/eggroll/files/eggroll.tar.gz" -C "$dir/build/$FATE_VER" 'eggroll'

    gmkdir -p "$target/roles/fateflow/files"
    gtar -cpz -f "$target/roles/fateflow/files/fate.tar.gz" -C "$dir/build/$FATE_VER" 'fate'
    gtar -cpz -f "$target/roles/fateflow/files/fateflow.tar.gz" -C "$dir/build/$FATE_VER" 'fateflow'

    gmkdir -p "$target/roles/fateboard/files"
    gtar -cpz -f "$target/roles/fateboard/files/fateboard.tar.gz" -C "$dir/build/$FATE_VER" 'fateboard'

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_ansible_offline
{
    local name="AnsibleFATE_${FATE_VER}_${RELE_VER}_offline"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    target="$target" filepath="$filepath" include_large_files=1 package_ansible
}

function package_ansible_online
{
    local name="AnsibleFATE_${FATE_VER}_${RELE_VER}_online"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    target="$target" filepath="$filepath" include_large_files=0 package_ansible
}

[ "$PULL_GIT" -gt 0 ] && git_pull

get_versions
: "${FATE_VER:=${versions[fate]}}"

[ "$CHEC_BRA" -gt 0 ] && check_branch

get_resources

[ "$SKIP_BUI" -gt 0 ] ||
{
    [ "$BUIL_PYP" -gt 0 ] && build_python_packages
    [ "$BUIL_EGG" -gt 0 ] && build_eggroll
    [ "$BUIL_BOA" -gt 0 ] && build_fateboard
    [ "$BUIL_FAT" -gt 0 ] && build_fate

    build_cleanup
}

[ "$SKIP_PKG" -gt 0 ] ||
{
    gmkdir -p "$dir/"{packages,dist}"/$FATE_VER"

    [ "$PACK_ARC" -gt 0 ] && package_fate_install
    [ "$PACK_PYP" -gt 0 ] && package_python_packages
    [ "$PACK_STA" -gt 0 ] && package_standalone_install
    [ "$PACK_DOC" -gt 0 ] && package_standalone_docker
    [ "$PACK_CLU" -gt 0 ] && package_cluster_install
    [ "$PACK_OFF" -gt 0 ] && package_ansible_offline
    [ "$PACK_ONL" -gt 0 ] && package_ansible_online
}

echo 'Done'
