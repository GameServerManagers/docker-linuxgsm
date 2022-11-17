#!/bin/bash
export HOME="/home/${USERNAME}"
# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ${GAMESERVER}"
  echo -e "================================="
  exec s6-setuidgid ${USERNAME} ./linuxgsm.sh ${GAMESERVER}
fi

# Clear functions directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  echo -e "not master branch, clearing functions directory"
  rm -rf /linuxgsm/lgsm/functions/*
elif [ -d "/linuxgsm/lgsm/functions" ]; then
  echo -e "ensure all functions are executable"
  chmod +x /linuxgsm/lgsm/functions/*
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles" >/dev/null 2>&1)" ]; then
  echo -e ""
  echo -e "Installing ${GAMESERVER}"
  echo -e "================================="
  exec s6-setuidgid ${USERNAME} ./${GAMESERVER} auto-install
  install=1
else
  # Donate to display logo
  exec s6-setuidgid ${USERNAME} ./${GAMESERVER} donate
fi
echo -e ""
echo -e "Starting Update Checks"
echo -e "================================="
nohup watch -n "${UPDATE_CHECK}" exec s6-setuidgid ${USERNAME} ./${GAMESERVER} update >/dev/null 2>&1 &
echo -e "update will check every ${UPDATE_CHECK} minutes"

# Update game server
if [ -z "${install}" ]; then
  echo -e ""
  echo -e "Checking for Update ${GAMESERVER}"
  echo -e "================================="
  exec s6-setuidgid ${USERNAME} ./${GAMESERVER} update
fi

echo -e ""
echo -e "Starting ${GAMESERVER}"
echo -e "================================="
exec s6-setuidgid ${USERNAME} ./${GAMESERVER} start
sleep 5
exec s6-setuidgid ${USERNAME} ./${GAMESERVER} details
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
