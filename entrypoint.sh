#!/bin/bash

exit_handler() {
  # Single-command mode: pass the signal to the running command instead of
  # stopping a server that is not running
  if [ "${singlecommand}" == "true" ] && [ -n "${childpid}" ]; then
    echo -e "Interrupting ${GAMESERVER} command"
    kill -TERM "${childpid}" 2> /dev/null
    wait "${childpid}"
    exit $?
  fi
  # Execute the shutdown commands
  echo -e "Stopping ${GAMESERVER}"
  exec gosu "${USER}" ./"${GAMESERVER}" stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler SIGQUIT SIGINT SIGTERM

singlecommand="false"
if [ "$#" -gt 0 ]; then
  singlecommand="true"
fi

DISTRO="$(grep "PRETTY_NAME" /etc/os-release | awk -F = '{gsub(/"/,"",$2);print $2}')"
echo -e ""
echo -e "Welcome to the LinuxGSM"
echo -e "================================================================================"
echo -e "CURRENT TIME: $(date)"
echo -e "BUILD TIME: $(cat /build-time.txt)"
echo -e "GAMESERVER: ${GAMESERVER}"
echo -e "DISTRO: ${DISTRO}"
echo -e ""
echo -e "USER: ${USER}"
echo -e "UID: ${UID}"
echo -e "GID: ${GID}"
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"
echo -e "LGSM_LOGDIR: ${LGSM_LOGDIR}"
echo -e "LGSM_SERVERFILES: ${LGSM_SERVERFILES}"
echo -e "LGSM_DATADIR: ${LGSM_DATADIR}"
echo -e "LGSM_CONFIG: ${LGSM_CONFIG}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"

export LGSM_GITHUBUSER=${LGSM_GITHUBUSER}
export LGSM_GITHUBREPO=${LGSM_GITHUBREPO}
export LGSM_GITHUBBRANCH=${LGSM_GITHUBBRANCH}
export LGSM_LOGDIR=${LGSM_LOGDIR}
export LGSM_SERVERFILES=${LGSM_SERVERFILES}
export LGSM_DATADIR=${LGSM_DATADIR}
export LGSM_CONFIG=${LGSM_CONFIG}

cd /app || exit

# start cron
cron

echo -e ""
echo -e "Machine ID"
echo -e "================================="
# The image ships one machine-id shared by every container built from it, and it
# changes on each rebuild. Some game servers (e.g. Hytale) encrypt saved credentials
# against it, so keep a per-install machine-id in /data that survives image updates.
machineid=""
if [ -f /data/.machine-id ]; then
  read -r machineid < /data/.machine-id
fi
if [[ "${machineid}" =~ ^[0-9a-f]{32}$ ]]; then
  echo -e "using machine-id from /data/.machine-id"
else
  echo -e "generating new machine-id in /data/.machine-id"
  machineid="$(tr -d '-' < /proc/sys/kernel/random/uuid)"
  if [[ ! "${machineid}" =~ ^[0-9a-f]{32}$ ]] || ! printf '%s\n' "${machineid}" > /data/.machine-id; then
    echo -e "ERROR: unable to create /data/.machine-id"
    exit 1
  fi
fi
for machineidfile in /etc/machine-id /var/lib/dbus/machine-id; do
  if [ -d "$(dirname "${machineidfile}")" ] && ! printf '%s\n' "${machineid}" > "${machineidfile}"; then
    echo -e "ERROR: unable to write ${machineidfile}"
    exit 1
  fi
done

echo -e ""
echo -e "Check Permissions"
echo -e "================================="
echo -e "setting UID to ${UID}"
usermod -u "${UID}" -m -d /data linuxgsm > /dev/null 2>&1
echo -e "setting GID to ${GID}"
groupmod -g "${GID}" linuxgsm
echo -e "updating permissions for /data"
chown -R "${USER}":"${USER}" /data
echo -e "updating permissions for /app"
chown -R "${USER}":"${USER}" /app
export HOME=/data

echo -e ""
echo -e "Switch to user ${USER}"
echo -e "================================="
exec gosu "${USER}" /app/entrypoint-user.sh "$@" &
childpid=$!
wait "${childpid}"
