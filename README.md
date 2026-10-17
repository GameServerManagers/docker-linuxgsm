# LinuxGSM Base Docker Image

<p align="center">
  <a href="https://linuxgsm.com"><img src="https://user-images.githubusercontent.com/4478206/197897104-bb718d2e-09a0-4f83-8e86-c829044750a9.jpg" alt="LinuxGSM"></a>
<br>
<a href="https://hub.docker.com/r/gameservermanagers/linuxgsm"><img src="https://img.shields.io/docker/pulls/gameservermanagers/linuxgsm.svg?style=flat-square&amp;logo=docker&amp;logoColor=white" alt="Docker Pulls"></a>
<a href="https://github.com/GameServerManagers/docker-linuxgsm/actions"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/GameServerManagers/docker-linuxgsm/action-docker-publish.yml?style=flat-square"></a>
<a href="https://www.codacy.com/gh/GameServerManagers/docker-linuxgsm/dashboard"><img src="https://img.shields.io/codacy/grade/42d400dcdd714ae080d77fcb40d00f1c?style=flat-square&logo=codacy&logoColor=white" alt="Codacy grade"></a>
<a href="https://developer.valvesoftware.com/wiki/SteamCMD"><img src="https://img.shields.io/badge/SteamCMD-000000?style=flat-square&amp;logo=Steam&amp;logoColor=white" alt="SteamCMD"></a>
<a href="https://github.com/GameServerManagers/docker-linuxgsm/blob/main/LICENSE.md"><img src="https://img.shields.io/github/license/gameservermanagers/docker-linuxgsm?style=flat-square" alt="MIT License"></a></p>

## About

[LinuxGSM](https://linuxgsm.com) is a command-line tool for deploying and managing Linux dedicated game servers.

This is the **base** LinuxGSM image: LinuxGSM, [SteamCMD](https://github.com/GameServerManagers/docker-steamcmd) and the packages most game servers need. Set `GAMESERVER` to any server LinuxGSM supports and the container installs and runs it. For a ready-made image per game, with that game's extra packages already installed, use [docker-gameserver](https://github.com/GameServerManagers/docker-gameserver).

The image is rebuilt weekly and published to [Docker Hub](https://hub.docker.com/r/gameservermanagers/linuxgsm) and [GitHub Container Registry](https://github.com/GameServerManagers/docker-linuxgsm/pkgs/container/linuxgsm):

```text
gameservermanagers/linuxgsm
ghcr.io/gameservermanagers/linuxgsm
```

Images are built for `linux/amd64` only.

## Tags

### Ubuntu

| Tag(s)             | Ubuntu release               | Notes                                           |
| ------------------ | ---------------------------- | ----------------------------------------------- |
| `latest`, `ubuntu` | 26.04 LTS (Resolute Raccoon) | Current LTS                                     |
| `ubuntu-26.04`     | 26.04 LTS (Resolute Raccoon) | Current LTS                                     |
| `ubuntu-24.04`     | 24.04 LTS (Noble Numbat)     | Previous LTS                                    |
| `ubuntu-22.04`     | 22.04 LTS (Jammy Jellyfish)  | Older LTS                                       |
| `ubuntu-20.04`     | 20.04 LTS (Focal Fossa)      | Standard support ended May 2025; may be removed |

`latest` moves to each new Ubuntu LTS shortly after it is released. Pin a specific `ubuntu-XX.04` tag if you need the base to stay the same.

### Other distros (testing only)

These images exist to test LinuxGSM on other distros. They work the same way as the Ubuntu images, but they are not supported releases.

| Tag(s)      | Release              |
| ----------- | -------------------- |
| `debian-13` | Debian 13 (Trixie)   |
| `debian-12` | Debian 12 (Bookworm) |
| `rocky-9`   | Rocky Linux 9        |

Rocky Linux 10 isn't available, because it no longer ships the 32-bit (i686) libraries SteamCMD needs.

## Quick start

Run a Just Cause 2 server (`jc2server`), keeping everything in `/path/to/jc2server` on the host:

```bash
docker run -d --name jc2server \
  -e GAMESERVER=jc2server \
  -v /path/to/jc2server:/data \
  -p 7777:7777/udp \
  --stop-timeout 60 \
  gameservermanagers/linuxgsm:latest
docker logs -f jc2server
```

Swap `jc2server` for any server in LinuxGSM's [server list](https://linuxgsm.com/servers/), and publish the ports that game uses. On the first start the container installs the game server, which can take a while for big games. If the game needs packages that aren't in the image, LinuxGSM installs them.

The same with Docker Compose:

```yaml
services:
  jc2server:
    image: gameservermanagers/linuxgsm:latest
    container_name: jc2server
    environment:
      - GAMESERVER=jc2server
    volumes:
      - /path/to/jc2server:/data
    ports:
      - "7777:7777/udp"
    stop_grace_period: 60s
    restart: unless-stopped
```

## What the container does

Each time the container starts, it:

1. Creates the LinuxGSM script for `GAMESERVER` the first time.
2. Installs the game server if `/data/serverfiles` is empty. Otherwise it checks for an update (`UPDATE_ON_START`), and validates the files if `VALIDATE_ON_START` is on.
3. Schedules an update check every `UPDATE_CHECK` minutes.
4. Starts the game server and shows its log.

`docker stop` runs LinuxGSM's `stop` command, so the server shuts down cleanly. Some servers take longer than Docker's default 10 seconds to stop, which is why the examples raise the timeout to 60 seconds.

The image's health check runs LinuxGSM's `monitor` command, which also restarts the game server if it stops responding.

## Configuration

| Variable            | Default     | What it does                                                                                              |
| ------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| `GAMESERVER`        | `jc2server` | The LinuxGSM server to run, for example `csgoserver` or `pzserver`                                        |
| `UPDATE_ON_START`   | `true`      | Check for a game server update each time the container starts                                             |
| `VALIDATE_ON_START` | `false`     | Check the game files each time the container starts (slow)                                                |
| `UPDATE_CHECK`      | `60`        | Minutes between update checks while the server runs. `0` turns them off; `60` or more checks once an hour |
| `UID`               | `1000`      | User ID that owns the files in `/data`                                                                    |
| `GID`               | `1000`      | Group ID that owns the files in `/data`                                                                   |
| `LGSM_GITHUBBRANCH` | `master`    | The LinuxGSM branch to use. Any other branch, such as `develop`, is downloaded on start                   |
| `LGSM_DEV`          | `false`     | Turn on LinuxGSM's developer mode                                                                         |

Game server settings live in LinuxGSM's own config files in `/data/config-lgsm`. See the [LinuxGSM docs](https://docs.linuxgsm.com) for what they can do.

## Data

Everything the server needs to keep is in `/data`, so mount it as a volume:

| Path                | What's in it                                          |
| ------------------- | ----------------------------------------------------- |
| `/data/serverfiles` | The game server files                                 |
| `/data/config-lgsm` | LinuxGSM config files                                 |
| `/data/log`         | Console and LinuxGSM logs                             |
| `/data/data`        | LinuxGSM data files                                   |
| `/data/.machine-id` | A machine ID that stays the same across image updates |

On every start, the container makes the files in `/data` owned by `UID` and `GID`.

## Running LinuxGSM commands

For a running server, use `docker exec` (here the container is named `jc2server`):

```bash
docker exec -it --user linuxgsm jc2server ./jc2server details
```

For one-off tasks on a **stopped** server, such as `details`, `validate` or `backup`, pass the command after the image name. The container runs it and exits with its status:

```bash
docker run --rm -v /path/to/jc2server:/data -e GAMESERVER=jc2server gameservermanagers/linuxgsm details
```

Don't do this against data that a running container is using. The two containers can't see each other, so commands such as `update` or `stop` wouldn't work safely.

## Building the image

There is a single `Dockerfile`. Choose the distro with the `DISTRO` (`ubuntu`, `debian` or `rocky`) and `DISTRO_VERSION` build arguments; the default is the current Ubuntu LTS. The image builds on the matching `ghcr.io/gameservermanagers/steamcmd:<distro>-<version>` image. Set `BASE_IMAGE` to build on a different one, such as a local steamcmd build.

```bash
docker build --build-arg DISTRO_VERSION=24.04 -t linuxgsm:ubuntu-24.04 .
docker build --build-arg DISTRO=debian --build-arg DISTRO_VERSION=13 -t linuxgsm:debian-13 .
docker build --build-arg DISTRO=rocky --build-arg DISTRO_VERSION=9 -t linuxgsm:rocky-9 .
docker build --build-arg BASE_IMAGE=steamcmd:rocky-9 -t linuxgsm:rocky-9 .
```

The packages differ by distro, but the result is the same. On Rocky Linux the image enables EPEL and CRB, installs the Red Hat package names, links `cron` to `crond`, and installs Node.js from NodeSource's rpm repository.

## How new releases are added

The images that get built are listed in [`versions.json`](versions.json). Each week a workflow checks for a new Ubuntu LTS, Debian stable or Rocky Linux release. It opens a pull request to add a new release when:

- the matching steamcmd image exists, and
- the new image builds and passes a smoke test.

The pull request also reports whether LinuxGSM's dependency check passes on the new release. A new Ubuntu LTS also takes the `latest` tag. Rocky Linux 10 is skipped because it has no i686 libraries.

## Dependency check

Another weekly workflow checks that every package in LinuxGSM's dependency list for each image (`lgsm/data/<distro>-<version>.csv`) can be installed. It only simulates the installs, so no game server files are downloaded. It checks both LinuxGSM branches:

- **`develop`:** a failure here fails the workflow, and means a list needs fixing in LinuxGSM.
- **`master`:** a failure here is reported but doesn't fail the workflow. It's usually already fixed in `develop` and waiting for the next LinuxGSM release.

To run it locally:

```bash
docker run --rm -u root -v "$PWD/tests:/tests:ro" --entrypoint /tests/check-deps.sh linuxgsm:debian-13 develop
```
