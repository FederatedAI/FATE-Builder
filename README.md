# FATE-Builder

## Dependencies

* [bash](https://formulae.brew.sh/formula/bash), [coreutils](https://formulae.brew.sh/formula/coreutils), [findutils](https://formulae.brew.sh/formula/findutils), [grep](https://formulae.brew.sh/formula/grep), [curl](https://formulae.brew.sh/formula/curl) (macOS only)

* Git & Git LFS

* Python3 & pip

* Node.js & npm

* JDK & Maven

* Docker

## Compatibility

- [`build.sh`](./build.sh) is written for modern GNU/Linux. macOS is based on BSD and it contains obsolete built-in utilities, which are not compatible with GNU utilities.

  So install them via [Homebrew](https://brew.sh) if you are using macOS.

- Python 3.6+ and the latest pip

  FATE standalone mode also works on Python 3.7 - 3.10, cluster mode is not tested.

- Node.js LTS version (v16) and the latest npm

  Node.js Current version (v17) is also supported, but you need to add `--openssl-legacy-provider` to `NODE_OPTIONS`. E.g:

  ```bash
  NODE_OPTIONS="--openssl-legacy-provider $NODE_OPTIONS" npm run build
  ```

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
| `REMO_DIR` | remove the directory `build` before building | `1` |
| `BUIL_PYP` | build and package Python packages (requires `docker`) | `1` |
| `COPY_ONL` | skip running `mvn clean package` & `npm run build` | `0` |
| `BUIL_EGG` | build and package Eggroll (requires `mvn`) | `1` |
| `BUIL_BOA` | build and package FATE-Board (requires `npm` & `mvn`) | `1` |
| `BUIL_FAT` | build and package FATE and FATE-Flow | `1` |
| `PUSH_ARC` | push the archive to COS (requires `coscli`) | `0` |

## Usage

1.  Make sure you are using Git to manage `FATE_DIR`. Switch to the right branch and initialize all submodules.

    You also need to switch branches on submodules because Git does not do it automatically.

2.  Copy `cos.example.yaml` to `cos.yaml` and fill in `secretid` and `secretkey`.

3.  Run `./build.sh`.

Examples:

```bash
./build.sh

/usr/local/bin/bash ./build.sh

export FATE_DIR=/path/to/fate
./build.sh

FATE_DIR=/path/to/fate ./build.sh

FATE_DIR=/path/to/fate PUSH_ARC=1 /usr/bin/env bash ./build.sh
```

## Docker (**UNTESTED**)

```bash
docker buildx build --compress --no-cache --progress=plain --pull --push --rm --squash --tag ccr.ccs.tencentyun.com/fate.ai/fate-builder:latest .
```