#!/bin/bash
# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ${GAMESERVER}"
  echo -e "================================="
  ./linuxgsm.sh ${GAMESERVER}
fi

# Clear functions directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  echo -e "not master branch, clearing functions directory"
  rm -rf /linuxgsm/lgsm/modules/*
elif [ -d "/linuxgsm/lgsm/modules" ]; then
  echo -e "ensure all functions are executable"
  chmod +x /linuxgsm/lgsm/modules/*
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles" 2> /dev/null)" ]; then
  echo -e ""
  echo -e "Installing ${GAMESERVER}"
  echo -e "================================="
  ./${GAMESERVER} auto-install
  install=1
else
  # Donate to display logo
  ./${GAMESERVER} sponsor
fi
echo -e ""
echo -e "Starting Update Checks"
echo -e "================================="
nohup watch -n "${UPDATE_CHECK}" ./${GAMESERVER} update > /dev/null 2>&1 &
echo -e "update will check every ${UPDATE_CHECK} minutes"

# Update game server
if [ -z "${install}" ]; then
  echo -e ""
  echo -e "Checking for Update ${GAMESERVER}"
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
  tmux set -g status off && tmux attach 2> /dev/null
fi

exec "$@"
