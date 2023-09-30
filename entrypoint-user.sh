#!/bin/bash

exit_handler_user() {
  # Execute the shutdown commands
  echo -e "Stopping ${GAMESERVER}"
  ./"${GAMESERVER}" stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler_user SIGQUIT SIGINT SIGTERM

execute_hook_directory() {
  for f in $1; do
    if ! bash $f
    then
      echo "Failed running hook \"$f\""
      exit 1
    fi
  done
}

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ${GAMESERVER}"
  echo -e "================================="
  ./linuxgsm.sh "${GAMESERVER}"
fi

# Clear modules directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  echo -e "not master branch, clearing modules directory"
  rm -rf /app/lgsm/modules/*
  ./"${GAMESERVER}" update-lgsm
elif [ -d "/app/lgsm/modules" ]; then
  echo -e "ensure all modules are executable"
  chmod +x /app/lgsm/modules/*
fi

# Run pre-install scripts
if [ -d "/app/hooks/pre-install" ]; then
  echo -e ""
  echo -e "Executing pre-install hooks"
  echo -e "================================="
  execute_hook_directory "/app/hooks/pre-install/*.sh"
fi

# Install game server
if [ -z "$(ls -A -- "/data/serverfiles" 2> /dev/null)" ]; then
  echo -e ""
  echo -e "Installing ${GAMESERVER}"
  echo -e "================================="
  ./"${GAMESERVER}" auto-install
  install=1
else
  echo -e ""
  # Sponsor to display LinuxGSM logo
  ./"${GAMESERVER}" sponsor
fi
echo -e ""
echo -e "Starting Update Checks"
echo -e "================================="
nohup watch -n "${UPDATE_CHECK}" ./"${GAMESERVER}" update > /dev/null 2>&1 &
minutes=$((UPDATE_CHECK / 60))
echo -e "update will check every ${minutes} minutes"

# Update game server
if [ -z "${install}" ]; then
  echo -e ""
  echo -e "Checking for Update ${GAMESERVER}"
  echo -e "================================="
  ./"${GAMESERVER}" update
fi

# Run pre-install scripts
if [ -d "/app/hooks/post-install" ]; then
  echo -e ""
  echo -e "Executing post-install hooks"
  echo -e "================================="
  execute_hook_directory "/app/hooks/post-install/*.sh"
fi

echo -e ""
echo -e "Starting ${GAMESERVER}"
echo -e "================================="
./"${GAMESERVER}" start
sleep 5
./"${GAMESERVER}" details
sleep 2
echo -e "Tail log files"
echo -e "================================="
tail -F "${LGSM_LOGDIR}"/*/*.log &
wait
