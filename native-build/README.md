# FATE-Builder

## Dependencies

* [bash](https://formulae.brew.sh/formula/bash), [coreutils](https://formulae.brew.sh/formula/coreutils), [findutils](https://formulae.brew.sh/formula/findutils), [grep](https://formulae.brew.sh/formula/grep), [gawk](https://formulae.brew.sh/formula/gawk), [gnu-tar](https://formulae.brew.sh/formula/gnu-tar), [gnu-sed](https://formulae.brew.sh/formula/gnu-sed) (macOS only)

* [GNU parallel](https://www.gnu.org/software/parallel/)

* Git & Git LFS

* Python3 & pip

* Node.js & npm

* JDK & Maven

* Docker

## Compatibility

- [`build.sh`](./build.sh) is written for modern GNU/Linux. macOS is based on BSD and it contains obsolete built-in utilities, which are not compatible with GNU utilities.

  So install them via [Homebrew](https://brew.sh) if you are using macOS.

- Python 3.8+ and the latest pip

  FATE standalone mode also works on Python 3.7 - 3.10, cluster mode is not tested.

- Node.js LTS version (v16) and the latest npm

- Java 8 and latest Maven

  FATE-Board works on both Java SE 8 and 17 (should work on Java SE 11 as well but not tested), Eggroll only works on Java SE 8.

- Always use the latest Docker version and enable [experimental features](https://docs.docker.com/engine/reference/commandline/dockerd/#description) and [buildkit](https://docs.docker.com/engine/reference/commandline/dockerd/#feature-options).

## Environments

| name | description | default |
| --- | --- | --- |
| `FATE_DIR` | the directory of FATE | `/data/projects/fate` |
| `PULL_GIT` | do `git pull` on `FATE_DIR` and all submodules <br/> it will not clone the repository nor initialize submodules | `1` |
| `PULL_OPT` | the options for `git pull` <br/> use `PULL_OPT=' ' ./build.sh` to remove all options | `--rebase --stat --autostash` |
| `CHEC_BRA` | check that the branch names of FATE, Flow, Board and Eggroll match the version numbers in `fate.env` | `1` |
| `SKIP_BUI` | skip the build steps and keep `build` directory unchanged <br/> turn on this flag will ignore `REMO_DIR`, `BUIL_PYP`, `COPY_ONL`, `BUIL_EGG`, `BUIL_BOA` and `BUIL_FAT` | `0` |
| `BUIL_PYP` | build and package Python packages (requires `docker`) | `1` |
| `COPY_ONL` | skip running `mvn clean package` & `npm run build` | `0` |
| `BUIL_EGG` | build and package Eggroll (requires `mvn`) | `1` |
| `BUIL_BOA` | build and package FATE-Board (requires `npm` & `mvn`) | `1` |
| `BUIL_FAT` | build and package FATE and FATE-Flow | `1` |
| `SKIP_PKG` | skip packing the archives <br/> turn on this flag will ignore `PATH_CON`, `PATH_JDK`, `PATH_MYS`, `FATE_VER`, `RELE_VER`, `PACK_ARC`, `PACK_STA`, `PACK_DOC`, `PACK_CLU`, `PACK_OFF`, `PACK_ONL` and `PUSH_ARC` | `0` |
| `PATH_CON` | the download path of Miniconda on COS (requires `coscli`) | `cos://fate/Miniconda3-py38_4.12.0-Linux-x86_64.sh` |
| `PATH_JDK` | the download path of JDK on COS (requires `coscli`) | `cos://fate/jdk-8u192-linux-x64.tar.gz` |
| `PATH_MYS` | the download path of MySQL on COS (requires `coscli`) | `cos://fate/mysql-8.0.28.tar.gz` |
| `FATE_VER` | the version number of FATE (used on the archive filename) | automatically get it from `$FATE_DIR/fate.env` |
| `RELE_VER` | the release version (used on the archive filename) | `release` |
| `PACK_ARC` | package the archive `FATE_install_${FATE_VER}_${RELE_VER}.tar.gz` | `1` |
| `PACK_PYP` | package the archive `pip-packages-fate-${FATE_VER}.tar.gz` | `1` |
| `PACK_STA` | package the archive `standalone_fate_install_${FATE_VER}_${RELE_VER}.tar.gz` | `1` |
| `PACK_DOC` | package the archive `standalone_fate_docker_image_${FATE_VER}_${RELE_VER}.tar` | `1` |
| `PACK_CLU` | package the archive `fate_cluster_install_${FATE_VER}_${RELE_VER}.tar.gz` | `1` |
| `PACK_OFF` | package the archive `AnsibleFATE_${FATE_VER}_${RELE_VER}-offline.tar.gz` | `1` |
| `PACK_ONL` | package the archive `AnsibleFATE_${FATE_VER}_${RELE_VER}-online.tar.gz` | `1` |
| `PUSH_ARC` | push the archives to COS (requires `coscli`) | `0` |

## Usage

1.  Make sure you are using Git to manage `FATE_DIR`. Switch to the right branch and initialize all submodules.

    You also need to switch branches on submodules because Git does not do it automatically.

2.  Copy `cos.example.yaml` to `cos.yaml` and fill in `secretid` and `secretkey`.

3.  Run `./build.sh`.

Examples:

```bash
./build.sh

export FATE_DIR=/path/to/fate && ./build.sh

echo 'FATE_DIR=/path/to/fate' > .env && ./build.sh

FATE_DIR=/path/to/fate ./build.sh
```

## Build in Docker

```bash
docker buildx build --compress --no-cache --progress=plain --pull --push --rm --tag ccr.ccs.tencentyun.com/fate.ai/fate-builder:latest .
```
