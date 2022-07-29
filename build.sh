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
: "${PATH_CON:=cos://fate/Miniconda3-4.5.4-Linux-x86_64.sh}"
: "${PATH_JDK:=cos://fate/jdk-8u192.tar.gz}"
: "${PATH_MYS:=cos://fate/mysql-8.0.28.tar.gz}"
: "${PATH_RMQ:=cos://fate/rabbitmq-server-generic-unix-3.9.14.tar.xz}"
: "${PATH_SVR:=cos://fate/supervisor-4.2.4-py2.py3-none-any.whl}"
: "${PATH_PYM:=cos://fate/PyMySQL-1.0.2-py3-none-any.whl}"
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
    local target="$dir/build/eggroll"

    [ "$COPY_ONL" -gt 0 ] || mvn -DskipTests -f "$source/jvm/pom.xml" -q clean package

    grm -rf "$target"
    gmkdir -p "$target/lib"

    for module in 'core' 'roll_pair' 'roll_site'
    {
        gcp -af "$source/jvm/$module/target/eggroll-"${module//_/-}"-${versions[eggroll]}.jar" \
                "$source/jvm/$module/target/lib/"*.jar \
                "$target/lib"
    }

    gcp -af "$source/"{BUILD_INFO,bin,conf,data,deploy,python} "$target"
    gcp -af "$source/jvm/core/main/resources/"*.sql "$target/conf"
}

function build_fateboard
{
    local source="$FATE_DIR/fateboard"
    local target="$dir/build/fateboard"

    [ "$COPY_ONL" -gt 0 ] ||
    {
        mvn -DskipTests -f "$source/pom.xml" -q clean package
    }

    grm -rf "$target"
    gmkdir -p "$target/conf"

    gcp -af "$source/src/main/resources/application.properties" "$target/conf"
    gcp -af "$source/target/fateboard-${versions[fateboard]}.jar" \
            "$source/bin/service.sh" \
            "$target"

    gln -frs "$target/fateboard-${versions[fateboard]}.jar" "$target/fateboard.jar"
}

function build_python_packages
{
    local source="$FATE_DIR/python/requirements.txt"
    local target="$dir/build/pypkg"

    grm -rf "$target"
    gmkdir -p "$target"

    docker run --pull=always --rm \
        -v "$(greadlink -f ~/.config/pip):/root/.config/pip:ro" \
        -v "$source:/requirements.txt:ro" \
        -v "$target:/wheelhouse:rw" \
        quay.io/pypa/manylinux2014_x86_64:latest \
        /bin/bash -c \
        'yum install -q -y gmp-devel mpfr-devel libmpc-devel && \
        /opt/python/cp36-cp36m/bin/pip wheel -q -r /requirements.txt -w /wheelhouse || \
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

    sudo chown "$(id -u):$(id -g)" "$target/"*
}

function build_fate
{
    grm -rf "$dir/build/fate" "$dir/build/fateflow"
    gmkdir -p "$dir/build/fate/conf" "$dir/build/fate/proxy" "$dir/build/fateflow"

    gcp -af "$FATE_DIR/"{RELEASE.md,fate.env,bin,build,deploy,examples,python} \
        "$FATE_DIR/build/standalone-install-build/init.sh" "$dir/build/fate"
    gcp -af "$FATE_DIR/c/proxy" "$dir/build/fate/proxy/nginx"
    gcp -af "$FATE_DIR/conf/"!(local.*).yaml "$dir/build/fate/conf"
    gcp -af "$FATE_DIR/fateflow/"{RELEASE.md,bin,conf,examples,python} "$dir/build/fateflow"
}

function build_cleanup
{
    gfind "$dir/build" -type d -print0 | parallel -0Xj1 gchmod 755
    gfind "$dir/build" -type f -print0 | parallel -0Xj1 gchmod 644

    gfind "$dir/build" -iname '*.sh' -print0 | parallel -0Xj1 gchmod a+x

    gfind "$dir/build" -iname '__pycache__' -prune -print0 | parallel -0Xj1 grm -fr
    gfind "$dir/build" -iname '*.pyc' -print0 | parallel -0Xj1 grm -f
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
    coscli sync "cos://fate/fate/$FATE_VER/$RELE_VER/${filepath##*/}" "cos://fate/${filepath##*/}"
}

function package_fate_install
{
    local source="$dir/build/fate"
    local target="$dir/packages/FATE_install_$FATE_VER"
    local filepath="${target}_${RELE_VER}.tar.gz"

    grm -fr "$target"
    gmkdir -p "$target"

    for module in 'eggroll' 'fateboard' 'fateflow'
    {
        gtar -cpz -f "$target/$module.tar.gz" -C "$dir/build" "$module"
    }

    gfind "$source" -mindepth 1 -maxdepth 1 -type d -not -iname 'python' -print0 | \
        parallel -0 gtar -cpz -f "$target/{/}.tar.gz" -C "$source" '{/}'
    gtar -cpz -f "$target/fate.tar.gz" -C "$source" --transform 's#^python#fate/python#' 'python'

    gmd5sum "$target/"*.tar.gz | gawk '{ sub(/\/.+\//, ""); sub(/\.tar\.gz/, ""); print $2 ":" $1 }' \
        >"$target/packages_md5.txt"

    gfind "$source" -mindepth 1 -maxdepth 1 -type f -not -iname 'init.sh' -print0 | \
        parallel -0Xj1 gcp -af '{}' "$target"
    gcp -af "$source/python/requirements.txt" "$target"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_python_packages
{
    local name="pip-packages-fate-$FATE_VER"
    local filepath="$dir/packages/$name.tar.gz"

    gtar -cpz -f "$filepath" -C "$dir/build" --transform "s/^pypkg/$name/" 'pypkg'
    filepath="$filepath" push_archive
}

function package_standalone
{
    grm -fr "$target"
    gmkdir -p "$target/fate"

    gcp -af "$dir/build/fate/"!(python*|proxy*) "$dir/build/"{fateboard,fateflow} "$target"
    gcp -af  "$dir/build/fate/python" "$target/fate"
    gln -frs "$target/fate/python/requirements.txt" "$target/requirements.txt"

    gmkdir -p "$target/env/"{jdk,python36}
    gcp -af "${resources[jdk]}" "$target/env/jdk"
    gcp -af "${resources[conda]}" "$target/env/python36"

    gcp -af "$dir/build/pypkg" "$target/env/pypi"
}

function package_standalone_install
{
    local target="$dir/packages/standalone_fate_install_$FATE_VER"
    local filepath="${target}_${RELE_VER}.tar.gz"

    target="$target" package_standalone

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_standalone_docker
{
    local target="$dir/packages/standalone_fate_docker_image_$FATE_VER"
    local filepath="${target}_${RELE_VER}.tar.gz"

    local image_hub='federatedai/standalone_fate'
    local image_tcr='ccr.ccs.tencentyun.com/federatedai/standalone_fate'

    local image_tag="$FATE_VER"
    [ "$RELE_VER" == 'release' ] || image_tag+="-$RELE_VER"

    target="$target" package_standalone

    docker buildx build --compress --progress=plain --pull --rm \
        --file "$dir/Dockerfile.Centos" --tag "$image_hub:$image_tag" "$target"

    docker save "$image_hub:$image_tag" | gzip > "$filepath"
    filepath="$filepath" push_archive

    docker tag "$image_hub:$image_tag" "$image_tcr:$image_tag"
    [ "$PUSH_ARC" -gt 0 ] && docker push "$image_tcr:$image_tag"
}

function package_cluster_install
{
    local name='fate-cluster-install'
    local source="$dir/templates/$name"
    local target="$dir/packages/$name-$FATE_VER"
    local filepath="${target%/*}/${name//-/_}_${FATE_VER}_${RELE_VER}-c7-u18.tar.gz"

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/${versions[fate]}/" "$target/allInone/conf/setup.conf"

    gmkdir -p "$target/python-install/files"
    gcp -af "${resources[conda]}" "$dir/build/fate/python/requirements.txt" "$dir/build/pypkg" "$target/python-install/files"

    gmkdir -p "$target/java-install/files"
    gcp -af "${resources[jdk]}" "$target/java-install/files"

    gmkdir -p "$target/mysql-install/files"
    gcp -af "${resources[mysql]}" "$dir/build/eggroll/conf/create-eggroll-meta-tables.sql" "$target/mysql-install/files"

    gmkdir -p "$target/eggroll-install/files"
    gcp -af "$dir/build/eggroll" "$target/eggroll-install/files"

    gmkdir -p "$target/fate-install/files"
    gcp -af "$dir/build/fate" "$dir/build/fateflow" "$dir/build/fateboard" "$target/fate-install/files"

    gmkdir -p "$target/allInone/logs"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_ansible_offline
{
    local name='AnsibleFATE'
    local source="$dir/templates/$name"
    local target="$dir/packages/$name-$FATE_VER-$RELE_VER-offline"
    local filepath="${target%/*}/${name}_${FATE_VER}_${RELE_VER}-offline.tar.gz"

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/${versions[fate]}/" "$target/deploy/files/fate_init"

    gmkdir -p "$target/roles/python/files"
    gcp -af "${resources[conda]}" "$dir/build/fate/python/requirements.txt" "$target/roles/python/files"
    gtar -cpz -f "$target/roles/python/files/pypi.tar.gz" -C "$dir/build" --transform "s/^pypkg/pypi/" 'pypkg'

    gmkdir -p "$target/roles/java/files"
    gcp -af "${resources[jdk]}" "$target/roles/java/files"

    gmkdir -p "$target/roles/mysql/files"
    gcp -af "${resources[mysql]}" "$target/roles/mysql/files"

    gmkdir -p "$target/roles/rabbitmq/files"
    gcp -af "${resources[rabbitmq]}" "$target/roles/rabbitmq/files"

    gmkdir -p "$target/roles/supervisor/files"
    gln -frs "$target/roles/python/files/${resources[conda]##*/}" "$target/roles/supervisor/files"
    gcp -af "${resources[supervisor]}" "${resources[pymysql]}" "$target/roles/supervisor/files"

    gtar -cpz -f "$target/roles/check/files/build.tar.gz" -C "$dir/build/fate" 'build'
    gtar -cpz -f "$target/roles/check/files/deploy.tar.gz" -C "$dir/build/fate" 'deploy'

    gmkdir -p "$target/roles/eggroll/files"
    gcp -af "$dir/build/eggroll/conf/create-eggroll-meta-tables.sql" "$target/roles/eggroll/files"
    gtar -cpz -f "$target/roles/eggroll/files/eggroll.tar.gz" -C "$dir/build" 'eggroll'

    gmkdir -p "$target/roles/fateflow/files"
    gtar -cpz -f "$target/roles/fateflow/files/fate.tar.gz" -C "$dir/build" 'fate'
    gtar -cpz -f "$target/roles/fateflow/files/fateflow.tar.gz" -C "$dir/build" 'fateflow'

    gmkdir -p "$target/roles/fateboard/files"
    gtar -cpz -f "$target/roles/fateboard/files/fateboard.tar.gz" -C "$dir/build" 'fateboard'

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_ansible_online
{
    local name='AnsibleFATE'
    local source="$dir/templates/$name"
    local target="$dir/packages/$name-$FATE_VER-$RELE_VER-online"
    local filepath="${target%/*}/${name}_${FATE_VER}_${RELE_VER}-online.tar.gz"

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/${versions[fate]}/" "$target/deploy/files/fate_init"

    for module in 'python' 'java' 'mysql' 'rabbitmq' 'supervisor' 'eggroll' 'fateflow' 'fateboard'
    {
        gmkdir -p "$target/roles/$module/files"
    }

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

[ "$PULL_GIT" -gt 0 ] && git_pull

get_versions
: "${FATE_VER:=${versions[fate]}}"

[ "$CHEC_BRA" -gt 0 ] && check_branch

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
    get_resources

    gmkdir -p "$dir/packages"

    [ "$PACK_ARC" -gt 0 ] && package_fate_install
    [ "$PACK_PYP" -gt 0 ] && package_python_packages
    [ "$PACK_STA" -gt 0 ] && package_standalone_install
    [ "$PACK_DOC" -gt 0 ] && package_standalone_docker
    [ "$PACK_CLU" -gt 0 ] && package_cluster_install
    [ "$PACK_OFF" -gt 0 ] && package_ansible_offline
    [ "$PACK_ONL" -gt 0 ] && package_ansible_online
}

echo 'Done'
