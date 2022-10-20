#
# LinuxGSM Base Dockerfile
#
# https://github.com/GameServerManagers/docker-linuxgsm
#

FROM gameservermanagers/steamcmd:ubuntu-22.04

LABEL maintainer="LinuxGSM <me@danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root

## Install Base LinuxGSM Requirements
RUN echo "**** Install Base LinuxGSM Requirements ****" \
  && apt-get update \
  && apt-get install -y software-properties-common \
  && add-apt-repository multiverse \
  && apt-get update \
  && apt-get install -y \
  cron \
  bc \
  binutils \
  bsdmainutils \
  bzip2 \
  ca-certificates \
  cpio \
  curl \
  distro-info \
  file \
  git \
  gzip \
  hostname \
  jq \
  lib32gcc-s1 \
  lib32stdc++6 \
  netcat \
  python3 \
  sudo \
  tar \
  tini \
  tmux \
  unzip \
  util-linux \
  wget \
  xz-utils \
  # Docker Extras
  iproute2 \
  iputils-ping \
  nano \
  vim \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/*

# Install NodeJS
RUN echo "**** Install NodeJS ****" \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get update \
  && apt-get install -y nodejs \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/*

# Install GameDig https://docs.linuxgsm.com/requirements/gamedig
RUN echo "**** Install GameDig ****" \
  && npm install -g gamedig

ARG USERNAME=linuxgsm
ARG UID=1000
ARG GID=1000

## Add linuxgsm user
RUN echo "**** Add linuxgsm user ****" \
  # Create the user
  && groupadd --gid ${GID} ${USERNAME} \
  && useradd --uid ${UID} --gid ${GID} -m ${USERNAME} \
  && usermod --shell /bin/bash ${USERNAME} \
  && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME} \
  && chown ${USERNAME}:${USERNAME} /home/${USERNAME}

## Download linuxgsm.sh
RUN echo "**** Download linuxgsm.sh ****" \
  && set -ex \
  && wget -O linuxgsm.sh https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/master/linuxgsm.sh \
  && chmod +x /linuxgsm.sh

# Create linuxgsm symlinks
RUN echo "**** Create Symlinks ****" \
  ln -sn /home/linuxgsm/serverfiles /serverfiles; \
  ln -sn /home/linuxgsm/lgsm/config-lgsm /config-lgsm; \
  ln -sn /home/linuxgsm/lgsm/logs /logs

WORKDIR /home/linuxgsm
ENV PATH=$PATH:/home/linuxgsm
USER linuxgsm

# Run SteamCMD as LinuxGSM user
RUN echo "**** Prepare SteamCMD ****" \
  mkdir -pv /home/linuxgsm/.steam/root \
  mkdir -pv /home/linuxgsm/.steam/steam \
  steamcmd +quit

RUN echo "**** Get LinuxGSM Modules ****" \
  git clone --filter=blob:none --no-checkout --depth 1 --sparse https://github.com/GameServerManagers/LinuxGSM.git; \
  cd LinuxGSM; \
  git sparse-checkout set lgsm/functions; \
  git checkout; \
  mkdir -p /home/linuxgsm/lgsm/functions; \
  mv lgsm/functions/* /home/linuxgsm/lgsm/functions; \
  chmod +x /home/linuxgsm/lgsm/functions/*; \
  rm -rf /home/linuxgsm/LinuxGSM

# Add LinuxGSM cronjobs
RUN echo "**** Create Cronjobs ****"
RUN (crontab -l 2>/dev/null; echo "*/1 * * * * /home/linuxgsm/*server monitor > /dev/null 2>&1") | crontab -
RUN (crontab -l 2>/dev/null; echo "*/30 * * * * /home/linuxgsm/*server update > /dev/null 2>&1") | crontab -

COPY entrypoint.sh /home/linuxgsm/entrypoint.sh
