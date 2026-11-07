# Linux desktop toolchain on top of the flutter-rust image: the GTK3 embedder dependencies and the libraries that the
# plugins used by the app need (gstreamer for audio, libsecret for secure storage, appindicator for the tray).
# Licensed under Apache-2.0 (see LICENSE); the Ubuntu packages keep their own licenses.
ARG BASE=ghcr.io/samuelalvesg/flutter-rust:3.47.9
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgtk-3-dev liblzma-dev libstdc++-12-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        libsecret-1-dev libayatana-appindicator3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN flutter config --enable-linux-desktop >/dev/null

LABEL org.opencontainers.image.licenses="Apache-2.0"
