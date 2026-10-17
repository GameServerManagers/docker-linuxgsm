#!/bin/bash
#
# Checks every package in LinuxGSM's dependency list for this distro can be installed.
# Runs as root inside the image: tests/check-deps.sh [branch]
#

set -uo pipefail

branch="${1:-master}"
# shellcheck source=/dev/null
. /etc/os-release
csvname="${ID}-${VERSION_ID}.csv"
csvurl="https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/${branch}/lgsm/data/${csvname}"
csv="$(mktemp)"

echo "Checking ${csvname} from LinuxGSM ${branch}"
if ! curl -fsSL "${csvurl}" -o "${csv}"; then
  echo "::error::${csvname} not found on LinuxGSM ${branch}"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt-get update -qq

dotnetpackage="$(grep -o 'dotnet-runtime-[0-9.]*' "${csv}" | head -n 1)"
if [ -n "${dotnetpackage}" ] && ! apt-cache show "${dotnetpackage}" > /dev/null 2>&1; then
  echo "${dotnetpackage} not in ${ID} ${VERSION_ID} repos, adding the Microsoft repo as LinuxGSM does"
  if curl -fsSL "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb; then
    dpkg -i /tmp/packages-microsoft-prod.deb > /dev/null
    apt-get update -qq
  else
    echo "::error::No Microsoft repo for ${ID} ${VERSION_ID}"
  fi
fi

depall="$(awk -F, '$1=="all" {$1=""; print $0}' "${csv}")"
depsteamcmd="$(awk -F, '$1=="steamcmd" {$1=""; print $0}' "${csv}")"

# shellcheck disable=SC2086
if ! output="$(apt-get install -s -qq ${depall} ${depsteamcmd} 2>&1)"; then
  echo "::error::all/steamcmd: $(grep -E '^E:' <<< "${output}" | head -n 3 | tr '\n' ' ')"
  exit 1
fi

failed=()
checked=0
while IFS=, read -r shortname packages; do
  packages="${packages//$'\r'/}"
  case "${shortname}" in
    "" | all | steamcmd) continue ;;
  esac
  checked=$((checked + 1))
  if [ -z "${packages//,/}" ]; then
    continue
  fi
  # shellcheck disable=SC2086
  if ! output="$(apt-get install -s -qq ${depall} ${depsteamcmd} ${packages//,/ } 2>&1)"; then
    reason="$(grep -E '^E:' <<< "${output}" | head -n 3 | tr '\n' ' ')"
    echo "::error::${shortname}: ${reason}"
    failed+=("${shortname}")
  fi
done < "${csv}"

echo "Checked ${checked} servers, ${#failed[@]} failed"
if [ "${#failed[@]}" -gt 0 ]; then
  echo "Failed: ${failed[*]}"
  exit 1
fi
