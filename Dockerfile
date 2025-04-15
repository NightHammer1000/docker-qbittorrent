FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/linuxserver/baseimage-alpine:edge

# set version label
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_VERSION
ARG QBT_CLI_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

# install runtime packages and qbitorrent-cli
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    curl \
    grep \
    icu-libs \
    jq \
    p7zip \
    python3 \
    qt6-qtbase-sqlite && \
  # install qbittorrent-nox enhanced
  echo "**** install qbittorrent-nox enhanced ****" && \
  QBEE_TAG=$(curl -sL "https://api.github.com/repos/c0re100/qBittorrent-Enhanced-Edition/releases/latest" | jq -r '.tag_name') && \
  if [ -z "$QBEE_TAG" ]; then echo "Failed to fetch latest qbee tag" && exit 1; fi && \
  echo "**** downloading qbee version ${QBEE_TAG} ****" && \
  curl -o /usr/bin/qbittorrent-nox -L \
    "https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/${QBEE_TAG}/qbittorrent-nox-static-musl-x86_64" && \
  chmod +x /usr/bin/qbittorrent-nox && \
  # install qbittorrent-cli
  echo "***** install qbitorrent-cli ****" && \
  mkdir /qbt && \
  if [ -z ${QBT_CLI_VERSION+x} ]; then \
    QBT_CLI_VERSION=$(curl -sL "https://api.github.com/repos/fedarovich/qbittorrent-cli/releases/latest" \
    | jq -r '. | .tag_name'); \
  fi && \
  curl -o \
    /tmp/qbt.tar.gz -L \
    "https://github.com/fedarovich/qbittorrent-cli/releases/download/${QBT_CLI_VERSION}/qbt-linux-alpine-x64-net6-${QBT_CLI_VERSION#v}.tar.gz" && \
  tar xf \
    /tmp/qbt.tar.gz -C \
    /qbt && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /root/.cache \  
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 8080 6881 6881/udp

VOLUME /config
