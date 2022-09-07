# FATE 升级脚本

## 准备

1. 请根据实际情况修改 `config` 文件

2. 只支持使用 AnsibleFATE 部署的 FATE

3. FATE 1.8.3 和 1.9.0 升级了 Python 版本，请设置 `UPGRADE_PYTHON=1`

## 升级

```
bash upgrade.sh
```

默认脚本会自动下载 release 包，如无需下载，请设置 `DOWNLOAD=0`，手工下载 `"https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/${version}/release/fate_cluster_install_${DEST_VER}_release.tar.gz"` 并放到 "archives/$DEST_VER.tar.gz"

## 配置修改

### fateflow

旧版本配置文件：`$FATE_DIR/conf/local.service_conf.yaml`

新版本配置文件：`$FATE_DIR/conf/service_conf.yaml`

FATE 1.7.0+ 会同时载入两个配置文件，local 的优先级更高，建议删除 local 里没用的配置项

FATE 1.7.0 移除了 `work_mode` 并增加了 `default_engines`

```
default_engines:
  computing: eggroll
  federation: eggroll
  storage: eggroll
```

### fateboard

旧版本配置文件：`$FATE_DIR/fateboard/conf/application.properties.old`

新版本配置文件：`$FATE_DIR/fateboard/conf/application.properties`

fateboard 没有 config override，需手动更新

## 回滚

脚本会备份旧版本的文件和数据库到 `backups/` 下，如需回滚只需把所有文件还原到 `$FATE_DIR` 并导入 `$FLOW_DB.sql` 即可
