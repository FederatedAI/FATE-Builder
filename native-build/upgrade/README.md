# FATE 升级脚本

## 准备

1. 请根据实际情况修改 `config` 文件

2. 只支持使用 AnsibleFATE 部署的 FATE

3. FATE 1.8.3 和 1.9.0 升级了 Python 版本，请设置 `UPGRADE_PYTHON=1`

## 升级

请从 [wiki](https://github.com/FederatedAI/FATE/wiki/Download) 下载对应版本的 AnsibleFATE 离线包并放到 `archives/` 目录下

```bash
bash upgrade.sh
```

## 配置修改

### fateflow

旧版本配置文件：`$FATE_DIR/conf/local.service_conf.yaml`

新版本配置文件：`$FATE_DIR/conf/service_conf.yaml`

FATE 1.7.0+ 会同时载入两个配置文件，local 的优先级更高，建议删除 local 里没用的配置项

FATE 1.7.0 移除了 `work_mode` 并增加了 `default_engines`

```yaml
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
