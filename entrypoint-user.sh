#!/bin/bash

exit_handler_user() {
  # Execute the shutdown commands
  echo -e "Stopping ${GAMESERVER}"
  ./"${GAMESERVER}" stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap (normal mode only: in single-command mode a signal should end the
# command, not run stop)
if [ "$#" -eq 0 ]; then
  echo -e "Loading exit handler"
  trap exit_handler_user SIGQUIT SIGINT SIGTERM
fi

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

# If a command was passed in, run it and exit with its status
if [ "$#" -gt 0 ]; then
  echo -e ""
  echo -e "Running ${GAMESERVER} $*"
  echo -e "================================="
  # Only install commands may run before the game server is installed. Other
  # commands can create files in serverfiles, which would make the next normal
  # start skip the install.
  if [ -z "$(ls -A -- "${LGSM_SERVERFILES}" 2> /dev/null)" ] && [[ ! "$1" =~ ^(install|i|auto-install|ai)$ ]]; then
    echo -e "${GAMESERVER} is not installed yet. Start the container without a command to install it, or run auto-install."
    exit 1
  fi
  # exec so the command receives signals directly and its status is the exit status
  exec ./"${GAMESERVER}" "$@"
fi

# Install game server
if [ -z "$(ls -A -- "${LGSM_SERVERFILES}" 2> /dev/null)" ]; then
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

# Update or validate game server
if [ -z "${install}" ]; then
  echo -e ""
  if [ "${VALIDATE_ON_START,,}" = "true" ]; then
    echo -e "Validating ${GAMESERVER}"
    echo -e "================================="
    ./"${GAMESERVER}" validate
  fi
  if [ "${UPDATE_ON_START,,}" = "true" ]; then
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

update_check_schedule() {
  local minutes="$1"
  if [[ ! "${minutes}" =~ ^[0-9]+$ ]] || [ "${minutes}" -eq 0 ]; then
    return 1
  elif [ "${minutes}" -lt 60 ]; then
    echo "*/${minutes} * * * *"
  elif [ "${minutes}" -le 1440 ] && [ $((minutes % 60)) -eq 0 ]; then
    echo "0 */$((minutes / 60)) * * *"
  else
    return 1
  fi
}

crontab_apply() {
  local source new message crontabtest
  if [ -f "${CRONTAB_FILE}" ]; then
    source="custom:$(md5sum < "${CRONTAB_FILE}")"
  else
    source="default:${UPDATE_CHECK}"
  fi
  if [ "${source}" == "${crontabsource}" ]; then
    return
  fi
  crontabsource="${source}"
  new="$(mktemp)"
  if [ -f "${CRONTAB_FILE}" ]; then
    cp "${CRONTAB_FILE}" "${new}"
    message="using custom crontab ${CRONTAB_FILE} (UPDATE_CHECK is ignored)"
  elif [ -z "${UPDATE_CHECK}" ] || [ "${UPDATE_CHECK}" == "0" ]; then
    echo "# no scheduled tasks" > "${new}"
    message="update checks are disabled"
  else
    if ! schedule="$(update_check_schedule "${UPDATE_CHECK}")"; then
      echo -e "Warning: UPDATE_CHECK=${UPDATE_CHECK} is not a supported interval (1-59, or whole hours up to 1440); checking every 60 minutes instead"
      schedule="0 */1 * * *"
    fi
    echo "${schedule} /app/${GAMESERVER} update > /dev/null 2>&1" > "${new}"
    message="update will check on schedule: ${schedule}"
  fi
  if crontabtest="$(supercronic -no-reap -test "${new}" 2>&1)"; then
    cat "${new}" > "${crontab}"
    echo -e "Scheduled tasks: ${message}"
  else
    echo -e "Error: ${CRONTAB_FILE} is not a valid crontab, keeping the previous schedule"
    echo -e "${crontabtest}" | tail -n 1
  fi
  rm -f "${new}"
}

# Scheduled tasks
crontab="/tmp/crontab"
crontabsource=""
echo "# no scheduled tasks" > "${crontab}"
echo -e ""
echo -e "Scheduled Tasks"
echo -e "================================="
crontab_apply
supercronic -quiet -no-reap -passthrough-logs -inotify "${crontab}" &
while sleep 30; do
  crontab_apply
done &

echo -e ""
echo -e "Tail log files"
echo -e "================================="
tail -F "${LGSM_LOGDIR}"/console/*console.log "${LGSM_LOGDIR}"/script/*script.log &
wait
