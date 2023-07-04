#!/bin/bash

exit_handler() {
  # Execute the shutdown commands
  echo -e "Stopping ${GAMESERVER}"
  exec gosu "${USERNAME}" ./"${GAMESERVER}" stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler SIGQUIT SIGINT SIGTERM

DISTRO="$(grep "PRETTY_NAME" /etc/os-release | awk -F = '{gsub(/"/,"",$2);print $2}')"
echo -e ""
echo -e "Welcome to the LinuxGSM"
echo -e "================================================================================"
echo -e "CURRENT TIME: $(date)"
echo -e "BUILD TIME: $(cat /build-time.txt)"
echo -e "GAMESERVER: ${GAMESERVER}"
echo -e "DISTRO: ${DISTRO}"
echo -e ""
echo -e "USER: ${USERNAME}"
echo -e "UID: ${UID}"
echo -e "GID: ${GID}"
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"
echo -e "LGSM_LOGDIR: ${LGSM_LOGDIR}"
echo -e "LGSM_SERVERFILES: ${LGSM_SERVERFILES}"
echo -e "LGSM_CONFIG: ${LGSM_CONFIG}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"

export LGSM_GITHUBUSER=${LGSM_GITHUBUSER}
export LGSM_GITHUBREPO=${LGSM_GITHUBREPO}
export LGSM_GITHUBBRANCH=${LGSM_GITHUBBRANCH}
export LGSM_LOGDIR=${LGSM_LOGDIR}
export LGSM_SERVERFILES=${LGSM_SERVERFILES}
export LGSM_CONFIG=${LGSM_CONFIG}

cd /app || exit

echo -e ""
echo -e "Check Permissions"
echo -e "================================="
echo -e "setting UID to ${UID}"
usermod -u "${UID}" -m -d /data linuxgsm > /dev/null 2>&1
echo -e "setting GID to ${GID}"
groupmod -g "${GID}" linuxgsm
echo -e "updating permissions"
chown -R "${USERNAME}":"${USERNAME}" /data
export HOME=/data

echo -e ""
echo -e "Switch to user ${USERNAME}"
echo -e "================================="
exec gosu "${USERNAME}" /app/entrypoint-user.sh &
wait
