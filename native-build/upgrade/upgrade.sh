#!/usr/bin/env bash

set -euxo pipefail

dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$dir/config"

supported_versions=( '1.6.0' '1.6.1' '1.7.0' '1.7.1' '1.7.1.1' '1.7.2' '1.8.0' '1.9.0' )
# supported_versions=( '1.7.1.1' '1.7.3' )
# supported_versions=( '1.8.0' '1.8.1' '1.8.2' '1.8.3' )
current_version="$(grep -ioP '(?<=FATE=).+' "$FATE_DIR/fate.env")"
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

[[ "$(ps aux | grep -v grep | grep fate_flow_server)" || "$(ps aux | grep -v grep | grep fateboard)" ]] && exit 1

release_url="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/${DEST_VER}/release/fate_cluster_install_${DEST_VER}_release.tar.gz"
release_dir="$dir/archives/$DEST_VER"

rm -fr "$release_dir"
mkdir -p "$release_dir"

[ "$DOWNLOAD" -gt 0 ] && curl -fsSL -o "$release_dir.tar.gz" "$release_url"
tar -pxz -f "$release_dir.tar.gz" -C "$release_dir" --strip-components=1

backup_dir="$dir/backups/$(date '+%Y%m%d_%H%M%S')_$current_version"

[ -e "$backup_dir" ] && exit 1
mkdir -p "$backup_dir"

mysql_options="--protocol=TCP --host=$MYSQL_HOST --port=$MYSQL_PORT --user=$MYSQL_USER --password=$MYSQL_PASSWD"
"$MYSQL_DIR/bin/mysqldump" $mysql_options --databases "$FLOW_DB" --add-drop-database --result-file="$backup_dir/$FLOW_DB.sql"

find "$FATE_DIR" -name 'jobs' -exec mv '{}' "$backup_dir" ';' -quit
find "$FATE_DIR" -name 'model_local_cache' -exec mv '{}' "$backup_dir" ';' -quit

for name in 'RELEASE.md' 'conf' 'examples' 'fate.env' 'fateboard' 'fateflow' 'python'
{
    [ -e "$FATE_DIR/$name" ] && mv "$FATE_DIR/$name" "$backup_dir"
}

cp -af "$VENV_DIR" "$backup_dir"

cp -af "$release_dir/fate-install/files/"* "$FATE_DIR"
ln -frs "$FATE_DIR/fate/"{RELEASE.md,fate.env,examples} "$FATE_DIR"

cp -af "$backup_dir/"{jobs,model_local_cache} "$FATE_DIR/fateflow"

for name in 'fateboard' 'fateflow'
{
    mkdir -p "$LOG_DIR/$name"
    ln -fsT "$LOG_DIR/$name" "$FATE_DIR/$name/logs"
}

sed -Ei "s#PYTHONPATH=.+#PYTHONPATH=$FATE_DIR/fate/python:$FATE_DIR/fateflow/python:$FATE_DIR/eggroll/python#" "$FATE_DIR/bin/init_env.sh"

mkdir -p "$FATE_DIR/conf"
cp -af "$backup_dir/conf/service_conf.yaml" "$FATE_DIR/conf/local.service_conf.yaml"
cp -af "$FATE_DIR/fate/conf/service_conf.yaml" "$FATE_DIR/fate/python/federatedml/transfer_conf.yaml" "$FATE_DIR/conf"
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

for version in "${upgrade_list[@]:1}"
{
    [ -f "$dir/sql/$version.sql" ] && "$MYSQL_DIR/bin/mysql" $mysql_options --execute="source $dir/sql/$version.sql" "$FLOW_DB"
}

"$VENV_DIR/bin/pip" install -U -r "$FATE_DIR/fate/python/requirements.txt" -f "$release_dir/python-install/files/pypkg" --no-index

"$VENV_DIR/bin/pip" uninstall -y fate_client
cd "$FATE_DIR/fate/python/fate_client"
"$VENV_DIR/bin/python" setup.py install

"$VENV_DIR/bin/pip" uninstall -y fate_test
cd "$FATE_DIR/fate/python/fate_test"
"$VENV_DIR/bin/python" setup.py install
