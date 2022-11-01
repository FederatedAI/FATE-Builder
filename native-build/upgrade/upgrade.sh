#!/usr/bin/env bash

set -euxo pipefail

dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$dir/config"

supported_versions=( '1.7.0' '1.7.1' '1.7.1.1' '1.7.2' '1.8.0' '1.9.0' '1.9.1' )
current_version="$(grep -ioP '(?<=FATE=).+' "$FATE_DIR/fate.env")"

release_dir="$dir/archives/$DEST_VER"
backup_dir="$dir/backups/$(date '+%Y%m%d_%H%M%S')_$current_version"
mysql_options="--protocol=TCP --host=$MYSQL_HOST --port=$MYSQL_PORT --user=$MYSQL_USER --password=$MYSQL_PASSWD"

declare -a upgrade_list

for version in "${supported_versions[@]}"
{
    [ ${#upgrade_list[@]} -eq 0 ] &&
    {
        [ "$current_version" == "$version" ] && upgrade_list+=( "$version" )
        continue
    }

    upgrade_list+=( "$version" )
    [ "$DEST_VER" == "$version" ] && break
}

[[ ${#upgrade_list[@]} -lt 2 || ${upgrade_list[-1]} != "$DEST_VER" ]] && exit 1

rm -fr "$release_dir"
mkdir -p "$release_dir"

tar -pxz -f "$dir/archives/AnsibleFATE_${DEST_VER}_release"[-_]offline.tar.gz -C "$release_dir" --strip-components=1

[ -e "$backup_dir" ] && exit 1
mkdir -p "$backup_dir"

[ "$UPDATE_DATABASE" -gt 0 ] &&
{
    tar -pxz -f "$release_dir/roles/fateflow/files/fate.tar.gz" -C "$dir" --strip-components=3 'fate/deploy/upgrade/sql'
    for file in "$dir/sql/"*.sql; { mv "$file" "${file%/*}/${file##*-}"; }

    "$CONDA_DIR/bin/supervisorctl" -c "$SUPERVISOR_DIR/supervisord.conf" stop fate-fateflow

    "$MYSQL_DIR/bin/mysqldump" $mysql_options --databases "$FLOW_DB" --add-drop-database --result-file="$backup_dir/$FLOW_DB.sql"

    for version in "${upgrade_list[@]:1}"
    {
        [ -f "$dir/sql/$version.sql" ] && "$MYSQL_DIR/bin/mysql" $mysql_options --execute="source $dir/sql/$version.sql" "$FLOW_DB"
    }
}

pid="$("$CONDA_DIR/bin/supervisorctl" -c "$SUPERVISOR_DIR/supervisord.conf" pid || :)"
[ -n "$pid" ] && kill -s SIGTERM "$pid"

sleep 60
ps -p "$pid" >/dev/null || exit 1

find "$FATE_DIR" -name 'jobs' -exec mv '{}' "$backup_dir" ';' -quit
find "$FATE_DIR" -name 'model_local_cache' -exec mv '{}' "$backup_dir" ';' -quit

for name in 'RELEASE.md' 'conf' 'examples' 'fate.env' 'fateboard' 'fateflow' 'eggroll' 'python'
{
    [ -e "$FATE_DIR/$name" ] && mv "$FATE_DIR/$name" "$backup_dir"
}

[ "$UPGRADE_PYTHON" -gt 0 ] &&
{
    mv "$CONDA_DIR" "$backup_dir"

    "$release_dir/roles/python/files/Miniconda3"-*-Linux-x86_64.sh -b -f -p "$CONDA_DIR"
    "$CONDA_DIR/bin/pip3" install PyMySQL supervisor -f "$release_dir/roles/supervisor/files" --no-index
}

tar -pxz -f "$release_dir/roles/python/files/pypi.tar.gz" -C "$release_dir/roles/python/files"

mv "$VENV_DIR" "$backup_dir"
"$CONDA_DIR/bin/python3" -m venv "$VENV_DIR"

for name in 'eggroll' 'fateflow' 'fateboard'
{
    tar -pxz -f "$release_dir/roles/$name/files/$name.tar.gz" -C "$FATE_DIR"
}

tar -pxz -f "$release_dir/roles/fateflow/files/fate.tar.gz" -C "$FATE_DIR"
ln -frs "$FATE_DIR/fate/"{RELEASE.md,fate.env,examples} "$FATE_DIR"

cp -af "$release_dir/roles/eggroll/files/eggroll.sh" "$FATE_DIR/eggroll/bin/fate-eggroll.sh"

cp -af "$backup_dir/"{jobs,model_local_cache} "$FATE_DIR/fateflow" || mkdir -p "$FATE_DIR/fateflow/"{jobs,model_local_cache}

for name in 'fateboard' 'fateflow' 'eggroll'
{
    mkdir -p "$LOG_DIR/$name"
    rm -fr "$FATE_DIR/$name/logs"
    ln -fs "$LOG_DIR/$name" "$FATE_DIR/$name/logs"
}

for name in 'clustermanager' 'nodemanager' 'rollsite' 'fateboard' 'fateflow'
{
    path="$SUPERVISOR_DIR/supervisord.d/fate-$name.conf"
    [ -f "$path" ] && sed -Ei 's#^command=.+start$#\0ing#' "$path"
}

sed -Ei "s#PYTHONPATH=.+#PYTHONPATH=$FATE_DIR/fate/python:$FATE_DIR/fateflow/python:$FATE_DIR/eggroll/python#" "$FATE_DIR/bin/init_env.sh"

for name in 'eggroll.properties' 'route_table.json'
{
    [ -f "$backup_dir/eggroll/conf/$name" ] &&
    {
        mv "$FATE_DIR/eggroll/conf/$name" "$FATE_DIR/eggroll/conf/$name.new"
        cp -af "$backup_dir/eggroll/conf/$name" "$FATE_DIR/eggroll/conf"
    }
}

mkdir -p "$FATE_DIR/conf"

cp -af "$backup_dir/conf/local.service_conf.yaml" "$FATE_DIR/conf" || \
    cp -af "$backup_dir/conf/service_conf.yaml" "$FATE_DIR/conf/local.service_conf.yaml" || :

cp -af "$FATE_DIR/fate/conf/service_conf.yaml" "$FATE_DIR/fate/python/federatedml/transfer_conf.yaml" "$FATE_DIR/conf"

[ -f "$backup_dir/fateboard/conf/application.properties" ] &&
{
    cp -af "$backup_dir/fateboard/conf/application.properties" "$FATE_DIR/fateboard/conf/application.properties.old"

    board_conf_keys=(
        'server.port'
        'fateflow.url'
        'fateflow.http_app_key'
        'fateflow.http_secret_key'
        'server.board.login.username'
        'server.board.login.password'
        'fateboard.datasource.jdbc-url'
        'fateboard.datasource.username'
        'fateboard.datasource.password'
    )

    for key in "${board_conf_keys[@]}"
    {
        val="$(grep -oP "(?<=$key=).+" "$FATE_DIR/fateboard/conf/application.properties.old" || :)"
        [ -n "$val" ] && sed -Ei "s#$key=.+#$key=$val#" "$FATE_DIR/fateboard/conf/application.properties"
    }
}

"$VENV_DIR/bin/pip" install -U -r "$release_dir/roles/python/files/requirements.txt" -f "$release_dir/roles/python/files/pypi" --no-index

"$VENV_DIR/bin/pip" uninstall -y fate_client
cd "$FATE_DIR/fate/python/fate_client"
"$VENV_DIR/bin/python" setup.py install

"$VENV_DIR/bin/pip" uninstall -y fate_test
cd "$FATE_DIR/fate/python/fate_test"
"$VENV_DIR/bin/python" setup.py install

"$CONDA_DIR/bin/supervisord" -c "$SUPERVISOR_DIR/supervisord.conf"
