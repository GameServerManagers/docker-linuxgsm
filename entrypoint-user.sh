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

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ${GAMESERVER}"
  echo -e "================================="
  ./linuxgsm.sh "${GAMESERVER}"
fi

# Symlink LGSM_CONFIG to /app/lgsm/config-lgsm
if [ ! -d "/app/lgsm/config-lgsm" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_CONFIG}"
  echo -e "================================="
  ln -s "${LGSM_CONFIG}" "/app/lgsm/config-lgsm"
fi

# Symlink LGSM_SERVERCFG to /app/serverfiles
if [ ! -d "/app/serverfiles" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_SERVERCFG}"
  echo -e "================================="
  ln -s "${LGSM_SERVERFILES}" "/app/serverfiles"
fi

# Symlink LGSM_LOGDIR to /app/log
if [ ! -d "/app/log" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_LOGDIR}"
  echo -e "================================="
  ln -s "${LGSM_LOGDIR}" "/app/log"
fi

# Symlink LGSM_DATADIR to /app/lgsm/data
if [ ! -d "/app/lgsm/data" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_DATADIR}"
  echo -e "================================="
  ln -s "${LGSM_DATADIR}" "/app/lgsm/data"
fi

# npm install in /app/lgsm
if [ -f "/app/lgsm/package.json" ]; then
  echo -e ""
  echo -e "npm install in /app/lgsm"
  echo -e "================================="
  cd /app/lgsm || exit
  npm install
  cd /app || exit
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

# Enable developer mode
if [ "${LGSM_DEV}" == "true" ]; then
  echo -e "developer mode enabled"
  ./"${GAMESERVER}" developer
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

if [ -n "${UPDATE_CHECK}" ] && [ "${UPDATE_CHECK}" != "0" ]; then
  echo -e ""
  echo -e "Starting Update Checks"
  echo -e "================================="
  echo -e "*/${UPDATE_CHECK} * * * * /app/${GAMESERVER} update > /dev/null 2>&1" | crontab -
  echo -e "update will check every ${UPDATE_CHECK} minutes"
else
  echo -e ""
  echo -e "Update checks are disabled"
  echo -e "================================="
fi

# Update or validate game server
if [ -z "${install}" ]; then
  echo -e ""
    if [ "${VALIDATE_ON_START,,}" = "true" ]; then
    echo -e "Validating ${GAMESERVER}"
    echo -e "================================="
    ./"${GAMESERVER}" validate
  else
    echo -e "Checking for Update ${GAMESERVER}"
    echo -e "================================="
    ./"${GAMESERVER}" update
  fi
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
tail -F "${LGSM_LOGDIR}"/{console,script}/*{console,script}.log &
wait
