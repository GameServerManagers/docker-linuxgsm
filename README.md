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

## Scheduled tasks

Scheduled tasks are run by [Supercronic](https://github.com/aptible/supercronic) as the `linuxgsm` user. Jobs see the same environment variables as the container (for example `LGSM_SERVERFILES`). The container does not need root privileges to schedule them, so it works with `--security-opt no-new-privileges`.

Schedules use the container's timezone, which is UTC unless you set `TZ` (for example `TZ=Europe/London`).

Crash recovery does not need a scheduled task: the image's healthcheck already runs `monitor` every minute.

### Update checks (default)

Without a custom crontab, the server checks for updates every `UPDATE_CHECK` minutes (default `60`). Set `UPDATE_CHECK=0` to disable.

| `UPDATE_CHECK` | Runs                                                           |
| -------------- | -------------------------------------------------------------- |
| `1`-`59`       | Every N minutes. Values that divide 60 (15, 30) give even gaps |
| `60`-`1440`    | Every N/60 hours, on the hour. Must be a whole number of hours |
| Anything else  | Every 60 minutes, with a warning in the log                    |
| `0`            | Off                                                            |

### Custom crontab

To schedule your own tasks, create a crontab file at `/data/crontab` (change the path with `CRONTAB_FILE`). While the file exists it is used **instead of** `UPDATE_CHECK`, so include an update job if you still want one.

```text
# /data/crontab
*/30 * * * *  /app/rustserver update > /dev/null 2>&1
0 5 * * *     /app/rustserver restart > /dev/null 2>&1
30 4 * * *    /app/rustserver backup > /dev/null 2>&1
0 0 * * 0     /app/rustserver update-lgsm > /dev/null 2>&1
55 4 * * *    /app/rustserver send "say Restart in 5 minutes" > /dev/null 2>&1
```

| Task                         | Command                           | Notes                                         |
| ---------------------------- | --------------------------------- | --------------------------------------------- |
| Update the game server       | `update`                          | What `UPDATE_CHECK` schedules by default      |
| Restart                      | `restart`                         | For example daily, for games that leak memory |
| Backup                       | `backup`                          | Backups are stored under `/data`              |
| Update LinuxGSM              | `update-lgsm`                     | Weekly is plenty                              |
| Update mods / workshop items | `mods-update` / `workshop-update` | Games that support them                       |
| Send a console command       | `send "..."`                      | Games with console input                      |
| Wipe                         | `wipe`                            | Games with a wipe command, such as Rust       |

Edit the file on the host (if `/data` is a bind mount) or inside the container:

```bash
docker exec -it --user linuxgsm rustserver nano /data/crontab
```

- Creating, editing or deleting `/data/crontab` takes effect within 30 seconds, without a restart. Deleting it switches back to `UPDATE_CHECK`.
- Each change is checked first. If the file is invalid, the error is logged and the previous schedule stays active.
- A job is skipped if its previous run is still going, so a slow update never runs twice at once.
- Output that is not redirected appears in the container log (`docker logs`), which is useful when testing a new line.
- `crontab -e` is not available in the container; use `/data/crontab` instead.

You can also schedule from the host (host cron, a systemd timer or a Kubernetes CronJob) with `docker exec --user linuxgsm <container> ./<gameserver> <command>`.
