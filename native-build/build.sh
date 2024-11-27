#!/usr/bin/env bash

set -euxo pipefail
shopt -s expand_aliases extglob

: "${FATE_DIR:=/data/projects/llm/FATE}"
: "${LLM_DIR:=/data/projects/llm/LLM_test}"
: "${CLON_GIT:=0}"
: "${PULL_GIT:=0}"
: "${PULL_OPT:=--rebase --stat --autostash}"
: "${CHEC_BRA:=0}"
: "${SKIP_BUI:=0}"
: "${COPY_ONL:=0}"
: "${BUIL_PYP:=0}"
: "${BUIL_EGG:=1}"
: "${BUIL_BOA:=1}"
: "${BUIL_FAT:=1}"
: "${SKIP_PKG:=0}"
: "${PATH_CON:=cos://fate/resources/Miniconda3-py310_24.5.0-0-Linux-x86_64.sh}"
: "${PATH_JDK:=cos://fate/resources/jdk-8u345.tar.xz}"
: "${PATH_MYS:=cos://fate/resources/mysql-8.0.28.tar.gz}"
: "${PATH_RMQ:=cos://fate/resources/rabbitmq-server-generic-unix-3.9.14.tar.xz}"
: "${PATH_SVR:=cos://fate/resources/supervisor-4.2.4-py2.py3-none-any.whl}"
: "${PATH_PYM:=cos://fate/resources/PyMySQL-1.0.2-py3-none-any.whl}"
: "${PATH_WBE:=cos://fate/resources/wb-info-enc-1.0-SNAPSHOT.jar}"
: "${SYNC_RES:=1}"
: "${RELE_VER:=release}"
: "${LLM_VER:=2.0.0}"
: "${PACK_ARC:=1}"
: "${PACK_PYP:=1}"
: "${PACK_STA:=1}"
: "${PACK_DOC:=0}"
: "${PACK_CLU:=1}"
: "${PACK_OFF:=1}"
: "${PACK_ONL:=1}"
: "${PACK_LLM:=1}"
: "${PUSH_ARC:=0}"

commands=( 'date' 'dirname' 'readlink' 'mkdir' 'printf' 'cp' 'ln' 'grep'
           'xargs' 'chmod' 'rm' 'awk' 'find' 'tar' 'sed' 'md5sum')
tools=( 'git' 'mvn' 'npm' 'docker' )
modules=( 'fate' 'fate_flow' 'fateboard' 'eggroll' )

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

   # for module in 'core' 'roll_pair' 'roll_site'
   # {
   #     gcp -af "$source/jvm/$module/target/eggroll-"${module//_/-}"-${versions[eggroll]}.jar" \
   #             "$source/jvm/$module/target/lib/"*.jar \
   #             "$target/lib"
   # }
   # gcp -af "${resources[wbenc]}" "$target/lib"
   
   # gcp -af "$source/"{BUILD_INFO,bin,conf,data,deploy,python} "$target"
   # gcp -af "$source/jvm/core/main/resources/"*.sql "$target/conf"
   gtar -zxvf $FATE_DIR/eggroll/eggroll.tar.gz -C $target
}

function build_fateboard
{
    local source="$FATE_DIR/fate_board"
    local target="$dir/build/$FATE_VER/fateboard"

    [ "$COPY_ONL" -gt 0 ] ||
    {
        mvn -DskipTests -f "$source/pom.xml" -q clean package
    }

    grm -rf "$target"
    gmkdir -p "$target"

    #gcp -af "$source/src/main/resources/application.properties" "$target/conf"
    #gcp -af "$source/target/fateboard-${versions[fateboard]}.jar" \
    #        "$source/bin/service.sh" \
    #        "$source/RELEASE.md" \
    #        "$target"
    #gcp -af "$source/target/fateboard/fateboard-${versions[fateboard]}.jar" \
    #	    "$source/target/fateboard/service.sh" \
    #	    "$source/target/fateboard/conf" \
    #	    "$source/target/fateboard/lib" \
    #	    "$source/RELEASE.md" \
    #	    "$target"
    gcp -ap "$source/RELEASE.md" "$target"
    unzip "$source/target/fateboard-${versions[fateboard]}-release.zip" -d "$target"
    gln -frs "$target/fateboard-${versions[fateboard]}.jar" "$target/fateboard.jar"
}

function build_python_packages
{
    local source="$FATE_DIR/python/requirements.txt"
    local source_llm="/data/projects/llm/fate-llm/python/requirements.txt"
    local source_flow="$FATE_DIR/fate_flow/python/requirements.txt"
    local target="$dir/build/$FATE_VER/pypkg"

    grm -rf "$target"
    gmkdir -p "$target"
    
    if [ "$PACK_LLM" -gt 0 ]
    then
	echo "PACK_LLM is 1"
        docker run --pull=always --rm \
		-v "$(greadlink -f ~/.config/pip/pip.conf):/root/.config/pip/pip.conf:ro" \
		-v "$source_llm:/fate_llm/requirements.txt:ro" -v "$source_flow:/fate_flow/requirements.txt:ro" -v "$TEST_DIR/python/requirements.txt:/fate_test/requirements.txt:ro"  -v "$FATE_DIR/fate_client/python/requirements.txt:/fate_client/requirements.txt:ro" \
		-v "$FATE_DIR/python/requirements-fate.txt:/fate_flow/requirements-fate.txt:rw" -v "$FATE_DIR/fate_flow/python/requirements-container.txt:/fate_flow/requirements-container.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-flow.txt:/fate_flow/requirements-flow.txt:ro" -v "$FATE_DIR/fate_flow/python/requirements-eggroll.txt:/fate_flow/requirements-eggroll.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-rabbitmq.txt:/fate_flow/requirements-rabbitmq.txt:ro" -v "$FATE_DIR/fate_flow/python/requirements-pulsar.txt:/fate_flow/requirements-pulsar.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-spark.txt:/fate_flow/requirements-spark.txt:ro" -v "$target:/wheelhouse:rw" \
		quay.io/pypa/manylinux2014_x86_64:latest /bin/bash -c '

        sed -e "s!^mirrorlist=!#mirrorlist=!g" -e "s!^#baseurl=!baseurl=!g" \
		-e "s!http://mirror\.centos\.org!http://mirrors.tencentyun.com!g" \
		-i /etc/yum.repos.d/CentOS-*.repo && \

	sed -e "s!^metalink=!#metalink=!g" -e "s!^#baseurl=!baseurl=!g" \
	-e "s!http://download\.example/pub!http://mirrors.tencentyun.com!g" \
	-i /etc/yum.repos.d/epel*.repo && \

	echo "$(sed 's!https://download\.pytorch\.org/whl/cpu!https://download.pytorch.org/whl!g' /fate_flow/requirements-fate.txt)" > /fate_flow/requirements-fate.txt && \
	echo "$(sed 's/torch==1.13.1+cpu/torch==1.13.1/' /fate_flow/requirements-fate.txt)" > /fate_flow/requirements-fate.txt && \
	cat /fate_llm/requirements.txt
	cat /fate_client/requirements.txt && \	
	cat /fate_test/requirements.txt && \
	cat /fate_flow/requirements.txt && \
	cat /fate_flow/requirements-fate.txt && \
	cat /fate_flow/requirements-container.txt && \
	cat /fate_flow/requirements-flow.txt && \
	cat /fate_flow/requirements-rabbitmq.txt && \
	cat /fate_flow/requirements-eggroll.txt && \
	cat /fate_flow/requirements-pulsar.txt && \
	cat /fate_flow/requirements-spark.txt && \

	yum install -q -y gmp-devel mpfr-devel libmpc-devel && \
	    /opt/python/cp310-cp310/bin/pip wheel -q -r /fate_llm/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_flow/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_flow/requirements-fate.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_client/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_test/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com || \
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
    else
	echo "$PACK_LLM is 0"
	docker run --pull=always --rm \
		-v "$(greadlink -f ~/.config/pip/pip.conf):/root/.config/pip/pip.conf:ro" \
		-v "$source_flow:/fate_flow/requirements.txt:ro" -v "$TEST_DIR/python/requirements.txt:/fate_test/requirements.txt:ro"  -v "$FATE_DIR/fate_client/python/requirements.txt:/fate_client/requirements.txt:ro" \
		-v "$FATE_DIR/python/requirements-fate.txt:/fate_flow/requirements-fate.txt:ro" -v "$FATE_DIR/fate_flow/python/requirements-container.txt:/fate_flow/requirements-container.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-flow.txt:/fate_flow/requirements-flow.txt:ro" -v "$FATE_DIR/fate_flow/python/requirements-eggroll.txt:/fate_flow/requirements-eggroll.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-rabbitmq.txt:/fate_flow/requirements-rabbitmq.txt:ro" -v "$FATE_DIR/fate_flow/python/requirements-pulsar.txt:/fate_flow/requirements-pulsar.txt:ro" \
		-v "$FATE_DIR/fate_flow/python/requirements-spark.txt:/fate_flow/requirements-spark.txt:ro" -v "$target:/wheelhouse:rw" \
		quay.io/pypa/manylinux2014_x86_64:latest /bin/bash -c '
	        
	        sed -e "s!^mirrorlist=!#mirrorlist=!g" -e "s!^#baseurl=!baseurl=!g" \
		-e "s!http://mirror\.centos\.org!http://mirrors.tencentyun.com!g" \
		-i /etc/yum.repos.d/CentOS-*.repo && \

		sed -e "s!^metalink=!#metalink=!g" -e "s!^#baseurl=!baseurl=!g" \
		-e "s!http://download\.example/pub!http://mirrors.tencentyun.com!g" \
		-i /etc/yum.repos.d/epel*.repo && \
	        
	    cat /fate_client/requirements.txt && \	
		cat /fate_test/requirements.txt && \
		cat /fate_flow/requirements.txt && \
		cat /fate_flow/requirements-fate.txt && \
		cat /fate_flow/requirements-container.txt && \
		cat /fate_flow/requirements-flow.txt && \
		cat /fate_flow/requirements-rabbitmq.txt && \
		cat /fate_flow/requirements-eggroll.txt && \
		cat /fate_flow/requirements-pulsar.txt && \
		cat /fate_flow/requirements-spark.txt && \

		yum install -q -y gmp-devel mpfr-devel libmpc-devel && \
		/opt/_internal/cpython-3.10.14/bin/python -m pip install --upgrade pip && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_flow/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_flow/requirements-fate.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_client/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com && \
		/opt/python/cp310-cp310/bin/pip wheel -q -r /fate_test/requirements.txt -w /wheelhouse -i https://pypi.doubanio.com/simple --trusted-host pypi.doubanio.com || \
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
    fi

    sudo chown "$(id -u):$(id -g)" "$target/"*
}

function build_fate
{
    grm -rf "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fate_flow"
    gmkdir -p "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fate_flow"  "$dir/build/$FATE_VER/fate/fate_test"

    gcp -af "$FATE_DIR/"{RELEASE.md,fate.env,bin,examples,python,fate_client,configs} "$dir/build/$FATE_VER/fate"
    gcp -ap "$TEST_DIR/"{doc,LICENSE,python,README.md,README_zh.md} "$dir/build/$FATE_VER/fate/fate_test"
    gcp -af "$FATE_DIR/fate_flow/"{RELEASE.md,fateflow.env,bin,conf,examples,python} "$dir/build/$FATE_VER/fate_flow"

    #gcp -af "$FATE_DIR/conf/"!(local.*).yaml "$dir/build/$FATE_VER/fate/conf"
    #gcp -af "$FATE_DIR/c/proxy" "$dir/build/$FATE_VER/fate/proxy/nginx"
    gcp -af "$FATE_DIR/java/osx/deploy/osx" "$dir/build/$FATE_VER/fate/osx"

    gsed -i '/--extra-index-url/d' "$dir/build/$FATE_VER/fate_flow/python/requirements.txt"
    if [ "$PACK_LLM" -gt 0 ]
    then
	gcp -af "$LLM_DIR/python/fate_llm" "$dir/build/$FATE_VER/fate/python"
	gcp -af "$LLM_DIR/python/requirements.txt" "$dir/build/$FATE_VER/fate/python/fate_llm"
    fi
}

function build_cleanup
{
    gfind "$dir/build/$FATE_VER" -type d -print0 | parallel -0Xj1 gchmod 755
   # gfind "$dir/build/$FATE_VER" -type f -print0 | parallel -0Xj1 gchmod 644

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
    local source="$dir/build/$FATE_VER/fate_flow"
    local name="fate_install_${FATE_VER}_${RELE_VER}"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"

    grm -fr "$target"
    gmkdir -p "$target"

    for module in 'eggroll' 'fateboard' 'fate_flow'
    {
        gtar -cpz -f "$target/$module.tar.gz" -C "$dir/build/$FATE_VER" "$module"
    }
    gtar -cpz -f "$target/osx.tar.gz" -C "$dir/build/$FATE_VER/fate/" 'osx'

    gfind "$source" -mindepth 1 -maxdepth 1 -type d -not -iname 'python' -print0 | \
        parallel -0 gtar -cpz -f "$target/{/}.tar.gz" -C "$source" '{/}'
    gtar -cpz -f "$target/fate.tar.gz" -C "$source" --transform 's#^python#fate/python#' 'python'

    gmd5sum "$target/"*.tar.gz | gawk '{ sub(/\/.+\//, ""); sub(/\.tar\.gz/, ""); print $2 ":" $1 }' \
        >"$target/packages_md5.txt"

    gfind "$source" -mindepth 1 -maxdepth 1 -type f -print0 | \
        parallel -0Xj1 gcp -af '{}' "$target"
    gcp -af "$source/python/requirements.txt" "$target"
    gcp -af "$dir/build/$FATE_VER/fate/python/requirements-fate.txt" "$target"
    gcp -af "$source/python/requirements-flow.txt" "$target"
    gcp -af "$source/python/requirements-eggroll.txt" "$target"
    gcp -af "$source/python/requirements-rabbitmq.txt" "$target"
    gcp -af "$source/python/requirements-pulsar.txt" "$target"
    gcp -af "$source/python/requirements-spark.txt" "$target"
    gcp -af "$source/python/requirements-container.txt" "$target"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_python_packages
{
    local name="pip_packages_fate_${FATE_VER}"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"
    local pack_llm=$PACK_LLM

    if [ "$pack_llm" -gt 0 ]
    then
        name="pip_packages_fate_llm_${LLM_VER}"
        filepath="$dir/dist/$FATE_VER/$name.tar.gz"
    fi

    gtar -cpz -f "$filepath" -C "$dir/build/$FATE_VER" --transform "s/^pypkg/$name/" 'pypkg'
    filepath="$filepath" push_archive
}

function package_standalone
{
    local source="$dir/templates/standalone_fate"
    local pack_llm=$PACK_LLM

    grm -fr "$target"
    gmkdir -p "$target/fate"
   
    gcp -af "$dir/build/$FATE_VER/fate/"!(python*|proxy*) "$dir/build/$FATE_VER/"{fateboard,fate_flow} "$target"
    gcp -af  "$dir/build/$FATE_VER/fate/python" "$target/fate"
    grm -fr "$target/fate_test"
    gcp -af  "$dir/build/$FATE_VER/fate/fate_test" "$target"
    if [ "$pack_llm" -gt 0 ]
    then
	gmkdir -p "$target/fate_llm/python"
	gcp -af "$dir/build/$FATE_VER/fate/python/fate_llm" "$target/fate_llm/python"
	grm -fr "$target/fate/python/fate_llm"
    fi
    #gln -frs "$target/fate_flow/python/requirements.txt" "$target/requirements.txt"
    #gln -frs "$target/fate/python/requirements-fate.txt" "$target/requirements-fate.txt"
    #gln -frs "$target/fate_flow/python/requirements-flow.txt" "$target/requirements-flow.txt"
    #gln -frs "$target/fate_flow/python/requirements-eggroll.txt" "$target/requirements-eggroll.txt"
    #gln -frs "$target/fate_flow/python/requirements-rabbitmq.txt" "$target/requirements-rabbitmq.txt"
    #gln -frs "$target/fate_flow/python/requirements-pulsar.txt" "$target/requirements-pulsar.txt"
    #gln -frs "$target/fate_flow/python/requirements-spark.txt" "$target/requirements-spark.txt"
    #gln -frs "$target/fate_flow/python/requirements-container.txt" "$target/requirements-container.txt"

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
    local pack_llm="$PACK_LLM"
    if [ "$pack_llm" -gt 0 ]		    
    then			            
	name="standalone_fate_install_${FATE_VER}_llm_${LLM_VER}_${RELE_VER}"
	filepath="$dir/dist/$FATE_VER/$name.tar.gz"
        target="$dir/packages/$FATE_VER/$name"	
    fi
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
    echo "target is $target"
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
    local pack_llm=${PACK_LLM}
    
    if [ "$pack_llm" -gt 0 ]
    then
	name="fate_cluster_install_${FATE_VER}_LLM_${LLM_VER}_${RELE_VER}"
	target="$dir/packages/$FATE_VER/$name"
	filepath="$dir/dist/$FATE_VER/$name.tar.gz"
    fi

    grm -fr "$target"
    gcp -af "$source" "$target"

    gsed -i "s/#VERSION#/$FATE_VER/" "$target/allInone/conf/setup.conf"

    gmkdir -p "$target/python-install/files/fate_test" 
    gmkdir -p  "$target/python-install/files/fate_client"
    if [ "$pack_llm" -gt 0 ]
    then
	gmkdir -p "$target/python-install/files/fate_llm"
	gcp -af "$dir/build/$FATE_VER/fate/python/fate_llm/requirements.txt" "$target/python-install/files/fate_llm"
    fi
    gcp -af "${resources[conda]}" "$dir/build/$FATE_VER/fate_flow/python/requirements.txt" "$dir/build/$FATE_VER/pypkg" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate/fate_test/python/requirements.txt" "$target/python-install/files/fate_test"
    gcp -af "$dir/build/$FATE_VER/fate/fate_client/python/requirements.txt" "$target/python-install/files/fate_client"
    gcp -af "$dir/build/$FATE_VER/fate/python/requirements-fate.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-flow.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-eggroll.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-rabbitmq.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-pulsar.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-spark.txt" "$target/python-install/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-container.txt" "$target/python-install/files"

    gmkdir -p "$target/java-install/files"
    gcp -af "${resources[jdk]}" "$target/java-install/files"

    gmkdir -p "$target/mysql-install/files"
    gcp -af "${resources[mysql]}" "$dir/build/$FATE_VER/eggroll/conf/create-eggroll-meta-tables.sql" "$target/mysql-install/files"

    gmkdir -p "$target/eggroll-install/files"
    gcp -af "$dir/build/$FATE_VER/eggroll" "$target/eggroll-install/files"

    gmkdir -p "$target/fate-install/files"
    gcp -af "$dir/build/$FATE_VER/fate" "$dir/build/$FATE_VER/fate_flow" "$dir/build/$FATE_VER/fateboard" "$target/fate-install/files"

    gmkdir -p "$target/allInone/logs"

    gtar -cpz -f "$filepath" -C "${target%/*}" "${target##*/}"
    filepath="$filepath" push_archive
}

function package_ansible
{
    local source="$dir/templates/AnsibleFATE"

    grm -fr "$target"
    gcp -af "$source" "$target"

    [ "$pack_llm" -gt 0 ] &&
    {
	gsed -i "s/eggroll.rollsite.push.max.retry=3/eggroll.rollsite.push.max.retry=1000/" "$target/roles/eggroll/templates/eggroll.properties.jinja"
	gsed -i "s/eggroll.rollsite.push.long.retry=2/eggroll.rollsite.push.long.retry=999/" "$target/roles/eggroll/templates/eggroll.properties.jinja"
	gsed -i "s/eggroll.rollsite.push.max.retry=3/eggroll.rollsite.push.max.retry=1000/" "$target/roles/eggroll/templates/eggroll-exchange.properties.jinja"
	gsed -i "s/eggroll.rollsite.push.long.retry=2/eggroll.rollsite.push.long.retry=999/" "$target/roles/eggroll/templates/eggroll-exchange.properties.jinja"
	gmkdir -p "$target/roles/python/files/fate_llm"
	gcp -af "$dir/build/$FATE_VER/fate/python/fate_llm/requirements.txt" "$target/roles/python/files/fate_llm"
    }
    gsed -i "s/#VERSION#/$FATE_VER/" "$target/deploy/files/fate_init"

    gmkdir -p "$target/roles/python/files"
    gmkdir -p "$target/roles/python/files/fate_client"
    gmkdir -p "$target/roles/python/files/fate_test"
    gcp -af "$dir/build/$FATE_VER/fate/fate_client/python/requirements.txt" "$target/roles/python/files/fate_client"
    gcp -af "$dir/build/$FATE_VER/fate/fate_test/python/requirements.txt" "$target/roles/python/files/fate_test"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate/python/requirements-fate.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-flow.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-eggroll.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-rabbitmq.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-pulsar.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-spark.txt" "$target/roles/python/files"
    gcp -af "$dir/build/$FATE_VER/fate_flow/python/requirements-container.txt" "$target/roles/python/files"
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

    #gtar -cpz -f "$target/roles/check/files/deploy.tar.gz" -C "$dir/build/$FATE_VER/fate" 'deploy'

    gmkdir -p "$target/roles/eggroll/files"
    gcp -af "$dir/build/$FATE_VER/eggroll/conf/create-eggroll-meta-tables.sql" "$target/roles/eggroll/files"
    gtar -cpz -f "$target/roles/eggroll/files/eggroll.tar.gz" -C "$dir/build/$FATE_VER" 'eggroll'

    gmkdir -p "$target/roles/fateflow/files"
    gtar -cpz -f "$target/roles/fateflow/files/fate.tar.gz" -C "$dir/build/$FATE_VER" 'fate'
    gtar -cpz -f "$target/roles/fateflow/files/fate_flow.tar.gz" -C "$dir/build/$FATE_VER" 'fate_flow'
    gtar -cpz -f "$target/roles/fateflow/files/osx.tar.gz" -C "$dir/build/$FATE_VER/fate" 'osx'
    gcp -af "$target/roles/fateflow/files/osx.tar.gz" "$target/roles/eggroll/files"

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
    local pack_llm=$PACK_LLM

    if [ "$pack_llm" -gt 0 ]
    then
	name_llm="AnsibleFATE_${FATE_VER}_LLM_${LLM_VER}_${RELE_VER}_offline"
	target_llm="$dir/packages/$FATE_VER/${name_llm}"
	filepath_llm="$dir/dist/$FATE_VER/${name_llm}.tar.gz"
	#name="${name}" target="$target" filepath="$filepath" pack_llm="$pack_llm" include_large_files=1 package_ansible
	echo "${name_llm}"
	echo "${target_llm}"
	echo "${filepath_llm}"
	name="${name_llm}" target="${target_llm}" filepath="${filepath_llm}" pack_llm="$pack_llm" include_large_files=1 package_ansible
    else
	name="$name" target="$target" filepath="$filepath" pack_llm="$pack_llm" include_large_files=1 package_ansible
	 echo "$name"
	 echo "$target"
	 echo "$filepath"
    fi
    # target="$target" filepath="$filepath" include_large_files=1 package_ansible
}

function package_ansible_online
{
    local name="AnsibleFATE_${FATE_VER}_${RELE_VER}_online"
    local target="$dir/packages/$FATE_VER/$name"
    local filepath="$dir/dist/$FATE_VER/$name.tar.gz"
    local pack_llm=$PACK_LLM

    if [ "$pack_llm" -gt 0 ]
    then
        name_llm="AnsibleFATE_${FATE_VER}_LLM_${LLM_VER}_${RELE_VER}_online"
	target_llm="$dir/packages/$FATE_VER/${name_llm}"
	filepath_llm="$dir/dist/$FATE_VER/${name_llm}.tar.gz"
	echo "${name_llm}"
	echo "${target_llm}"
	echo "${filepath_llm}"
	name="${name_llm}" target="${target_llm}" filepath="${filepath_llm}" pack_llm="$pack_llm" include_large_files=0 package_ansible
    else
	name="$name" target="$target" filepath="$filepath" pack_llm="$pack_llm" include_large_files=0 package_ansible
        echo "$name"
	echo "$target"
	echo "$filepath"
    fi
    #target="$target" filepath="$filepath" include_large_files=0 package_ansible
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
