#!/bin/bash

exit_handler() {
  # Execute the shutdown commands
  echo "stopping ${GAMESERVER}"
  ./${GAMESERVER} stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo "Loading exit handler"
trap exit_handler SIGQUIT SIGINT SIGTERM

echo -e ""
echo -e "Welcome to the LinuxGSM"
echo -e "================================================================================"
echo -e "TIME: $(date)"
echo -e "SCRIPT TIME: $(cat /time.txt)"
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

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo ""
  echo "creating ./${GAMESERVER}"
  ./linuxgsm.sh ${GAMESERVER}
fi

if [ -d "/linuxgsm/lgsm/functions" ]; then
  echo ""
  echo "check all functions are executable"
  chmod +x /linuxgsm/lgsm/functions/*
fi

# Clear functions directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  rm -rf /linuxgsm/lgsm/functions/*
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles")" ]; then
  echo ""
  echo "installing ${GAMESERVER}"
  ./${GAMESERVER} auto-install
else
  # Donate to display logo
  ./${GAMESERVER} donate
fi

echo "starting cron"
cron

# Update game server
echo ""
echo "updating ${GAMESERVER}"
./${GAMESERVER} update

echo ""
echo "starting ${GAMESERVER}"
./${GAMESERVER} start
sleep 5
./${GAMESERVER} details
sleep 2
tail -F log/script/*

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
