#!/usr/bin/env bash

set -euxo pipefail
shopt -s expand_aliases

: "${FATE_DIR:=/data/projects/fate}"
: "${PULL_GIT:=1}"
: "${PULL_OPT:=--rebase --stat --autostash}"
: "${CHEC_BRA:=1}"
: "${SKIP_BUI:=0}"
: "${REMO_DIR:=1}"
: "${COPY_ONL:=0}"
: "${BUIL_PYP:=1}"
: "${BUIL_EGG:=1}"
: "${BUIL_BOA:=1}"
: "${BUIL_FAT:=1}"
: "${SKIP_PKG:=0}"
: "${PATH_CON:=cos://fate/Miniconda3-4.5.4-Linux-x86_64.sh}"
: "${PATH_JDK:=cos://fate/jdk-8u192-linux-x64.tar.gz}"
: "${PATH_MYS:=cos://fate/mysql-8.0.28.tar.gz}"
: "${RELE_VER:=release}"
: "${PACK_ARC:=1}"
: "${PACK_STA:=1}"
: "${PACK_DOC:=1}"
: "${PACK_CLU:=1}"
: "${PACK_OFF:=1}"
: "${PACK_ONL:=1}"
: "${PUSH_ARC:=0}"

commands=( 'date' 'dirname' 'readlink' 'mkdir' 'grep' 'printf' 'cp' 'ln' 'xargs' 'find' )
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
        alias "g$command=$command"
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

alias _git="git -C '$FATE_DIR'"
_git status >/dev/null

alias coscli="'$dir/bin/coscli-$plat' -c '$dir/cos.yaml'"
coscli ls 'cos://fate' >/dev/null

function git_pull
{
    _git pull $PULL_OPT
    _git submodule foreach --recursive 'git -C "$toplevel/$sm_path" pull '"$PULL_OPT"
}

function get_version
{
    versions["$1"]="$(ggrep -ioP "(?<=$1=).+" "$FATE_DIR/fate.env")"
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

    gmkdir -p "$target/lib"
    for module in 'core' 'roll_pair' 'roll_site'
    {
        gcp -af "$source/jvm/$module/target/eggroll-"${module//_/-}"-${versions[eggroll]}.jar" \
                "$source/jvm/$module/target/lib/"*.jar \
                "$target/lib"
    }

    gcp -af "$source/"{bin,conf,data,deploy,python} "$target"
    gcp -af "$source/jvm/core/main/resources/"*.sql "$target/conf"
}

function build_fateboard
{
    local source="$FATE_DIR/fateboard"
    local target="$dir/build/fateboard"

    [ "$COPY_ONL" -gt 0 ] ||
    {
        [ -n "$(node --help | ggrep -i -- '--openssl-legacy-provider')" ] && \
            declare -x NODE_OPTIONS="--openssl-legacy-provider ${NODE_OPTIONS:-}"

        npm --prefix "$source/resources-front-end" --quiet install
        npm --prefix "$source/resources-front-end" --quiet run build

        mvn -DskipTests -f "$source/pom.xml" -q clean package
    }

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

    gmkdir -p "$target"

    docker run --rm \
        -v "$(greadlink -f ~/.config/pip):/root/.config/pip:ro" \
        -v "$(greadlink -f ~/.cache/pip):/root/.cache/pip:rw" \
        -v "$source:/requirements.txt:ro" \
        -v "$target:/wheelhouse:rw" \
        quay.io/pypa/manylinux2014_x86_64:latest \
        /bin/bash -c \
        'yum install -q -y gmp-devel mpfr-devel libmpc-devel && \
        /opt/python/cp36-cp36m/bin/pip wheel -q -r /requirements.txt -w /wheelhouse'

    docker run --rm \
        -v "$target:/wheelhouse:rw" \
        quay.io/pypa/manylinux2014_x86_64:latest \
        /bin/bash -c '
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
}

function build_fate
{
    gmkdir -p "$dir/build/fate" "$dir/build/fateflow" "$dir/build/fate_examples"

    gcp -af "$FATE_DIR/python" "$dir/build/fate"
    gcp -af "$FATE_DIR/examples" "$dir/build/fate_examples/fate"

    gcp -af "$FATE_DIR/fateflow/"{bin,conf,python} "$dir/build/fateflow"
    gcp -af "$FATE_DIR/fateflow/examples" "$dir/build/fate_examples/fateflow"
}

[ "$PULL_GIT" -gt 0 ] && git_pull

declare -A versions
for module in "${modules[@]}"
{
    get_version "$module"
}

: "${FATE_VER:=${versions[fate]}}"

[ "$CHEC_BRA" -gt 0 ] && check_branch

[ "$SKIP_BUI" -gt 0 ] ||
{
    [ "$REMO_DIR" -gt 0 ] && rm -fr "$dir/build"

    [ "$BUIL_PYP" -gt 0 ] && build_python_packages
    [ "$BUIL_EGG" -gt 0 ] && build_eggroll
    [ "$BUIL_BOA" -gt 0 ] && build_fateboard
    [ "$BUIL_FAT" -gt 0 ] && build_fate

    gfind "$dir/build" -type d -exec chmod 755 {} \;
    gfind "$dir/build" -type f -exec chmod 644 {} \;

    gfind "$dir/build" -iname '*.sh' -exec chmod a+x {} \;

    gfind "$dir/build" -iname '__pycache__' -prune -exec rm -fr {} \;
    gfind "$dir/build" -iname '*.pyc' -exec rm -f {} \;
}

[ "$SKIP_PKG" -gt 0 ] ||
{
    echo 'TODO'
}

[ "$PUSH_ARC" -gt 0 ] &&
{
    echo 'TODO'
}

echo 'Done'
