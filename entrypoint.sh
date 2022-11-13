#!/usr/bin/with-contenv bash

exit_handler() {
  # Execute the shutdown commands
  echo -e "stopping ${GAMESERVER}"
  ./${GAMESERVER} stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler SIGQUIT SIGINT SIGTERM

echo -e ""
echo -e "Welcome to the LinuxGSM"
echo -e "================================================================================"
echo -e "CURRENT TIME: $(date)"
echo -e "BUILD TIME: $(cat /build-time.txt)"
echo -e "GAMESERVER: ${GAMESERVER}"
echo -e ""
echo -e "USER: ${USERNAME}"
echo -e "UID: ${UID}"
echo -e "GID: ${GID}"
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"

export LGSM_GITHUBUSER=${LGSM_GITHUBUSER}
export LGSM_GITHUBREPO=${LGSM_GITHUBREPO}
export LGSM_GITHUBBRANCH=${LGSM_GITHUBBRANCH}

cd /linuxgsm || exit

# permissions
usermod -u ${UID} linuxgsm
groupmod -g ${GID} linuxgsm
find /linuxgsm -user ${UID} -exec chown -h linuxgsm {} \;
find /linuxgsm -group ${GID} -exec chgrp -h linuxgsm {} \;
chown -R linuxgsm:linuxgsm /linuxgsm

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ./${GAMESERVER}"
  ./linuxgsm.sh ${GAMESERVER}
fi

# Clear functions directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  echo -e ""
  echo -e "not master branch, clearing functions directory"
  rm -rf /linuxgsm/lgsm/functions/*
elif [ -d "/linuxgsm/lgsm/functions" ]; then
  echo -e ""
  echo -e "check all functions are executable"
  chmod +x /linuxgsm/lgsm/functions/*
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles")" ]; then
  echo -e ""
  echo -e "Installing ${GAMESERVER}"
  echo -e "================================="
  ./${GAMESERVER} auto-install
  install=1
else
  # Donate to display logo
  ./${GAMESERVER} donate
fi

echo -e "Starting Monitor"
echo -e "================================="
#cron
nohup watch -n "${UPDATE_CHECK}" ./${GAMESERVER} update >/dev/null 2>&1 &

# Update game server
if [ -z "${install}" ]; then
  echo -e ""
  echo -e "Updating ${GAMESERVER}"
  echo -e "================================="
  ./${GAMESERVER} update
fi

echo -e ""
echo -e "Starting ${GAMESERVER}"
echo -e "================================="
./${GAMESERVER} start
sleep 5
./${GAMESERVER} details
sleep 2
echo -e "Tail log files"
echo -e "================================="
tail -F log/*/*.log

# with no command, just spawn a running container suitable for exec's
if [ $# = 0 ]; then
  tail -f /dev/null
else
  # execute the command passed through docker
  "$@"

  # if this command was a server start cmd
  # to get around LinuxGSM running everything in
  # tmux;
  # we attempt to attach to tmux to track the server
  # this keeps the container running
  # when invoked via docker run
  # but requires -it or at least -t
  tmux set -g status off && tmux attach 2>/dev/null
fi

exec "$@"
