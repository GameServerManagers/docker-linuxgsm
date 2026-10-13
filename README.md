# LinuxGSM Base Docker Image

## This is the base LinuxGSM image only

## Use <a href="https://github.com/GameServerManagers/docker-gameserver">docker-gameserver</a> for full game servers

<p align="center">
  <a href="https://linuxgsm.com"><img src="https://user-images.githubusercontent.com/4478206/197897104-bb718d2e-09a0-4f83-8e86-c829044750a9.jpg" alt="LinuxGSM"></a>
<br>
<a href="https://hub.docker.com/r/gameservermanagers/linuxgsm"><img src="https://img.shields.io/docker/pulls/gameservermanagers/linuxgsm.svg?style=flat-square&amp;logo=docker&amp;logoColor=white" alt="Docker Pulls"></a>
<a href="https://github.com/GameServerManagers/docker-linuxgsm/actions"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/GameServerManagers/docker-linuxgsm/action-docker-publish.yml?style=flat-square"></a>
<a href="https://www.codacy.com/gh/GameServerManagers/docker-linuxgsm/dashboard"><img src="https://img.shields.io/codacy/grade/42d400dcdd714ae080d77fcb40d00f1c?style=flat-square&logo=codacy&logoColor=white" alt="Codacy grade"></a>
<a href="https://developer.valvesoftware.com/wiki/SteamCMD"><img src="https://img.shields.io/badge/SteamCMD-000000?style=flat-square&amp;logo=Steam&amp;logoColor=white" alt="SteamCMD"></a>
<a href="https://github.com/GameServerManagers/docker-linuxgsm/blob/main/LICENSE.md"><img src="https://img.shields.io/github/license/gameservermanagers/docker-linuxgsm?style=flat-square" alt="MIT License"></a></p>

## About

LinuxGSM is a command-line tool for quick, simple deployment and management of Linux dedicated game servers. This container image builds weekly and is available on [Docker Hub](https://hub.docker.com/r/gameservermanagers/linuxgsm) as well as [GitHub Container Registry](https://github.com/GameServerManagers/docker-linuxgsm/pkgs/container/linuxgsm).

## Tags

- `latest`, `ubuntu` - Latest Ubuntu LTS release (currently 26.04)
- `ubuntu-26.04` - Ubuntu 26.04 LTS 'Resolute Raccoon'
- `ubuntu-24.04` - Ubuntu 24.04 LTS 'Noble Numbat'
- `ubuntu-22.04` - Ubuntu 22.04 LTS 'Jammy Jellyfish'
- `ubuntu-20.04` - Ubuntu 20.04 LTS 'Focal Fossa' (standard support ended May 2025; may be removed)

Images are built for `linux/amd64` only and use [gameservermanagers/steamcmd](https://github.com/GameServerManagers/docker-steamcmd) as their base.

## Building

There is a single `Dockerfile`; choose the Ubuntu release with the `UBUNTU_VERSION` build argument (defaults to the current LTS):

```bash
docker build --build-arg UBUNTU_VERSION=24.04 -t linuxgsm:ubuntu-24.04 .
```

The versions that get built are listed in [`ubuntu-versions.json`](ubuntu-versions.json). A weekly workflow checks for a new Ubuntu LTS. Once the matching steamcmd base image exists, and the image builds and passes a smoke test, it opens a pull request to add the new version.

## Running a single command

Arguments after the image name are passed to the game server script, which runs them and exits with their status. This is useful for one-off tasks on a **stopped** server, such as `details`, `validate` or `backup`:

```bash
docker run --rm -v /path/to/data:/data -e GAMESERVER=gmodserver gameservermanagers/linuxgsm details
```

Do not run a command this way against a volume that a running container is using. The two containers cannot see each other, so commands such as `update` or `stop` would not work safely. For a running server, use `docker exec` instead (here the container is named `gmodserver`):

```bash
docker exec -it --user linuxgsm gmodserver ./gmodserver details
```
