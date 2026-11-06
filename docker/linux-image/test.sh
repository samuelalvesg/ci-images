#!/usr/bin/env bash
# Smoke test for the flutter-linux image: toolchain, the pkg-config modules the plugins need and a real Linux build.
# Usage: docker/linux-image/test.sh <image> [--no-build]
set -euo pipefail
image="${1:?image}"; skip_build="${2:-}"
run() { docker run --rm -e HOME=/github/home "$image" bash -c "$1"; }

run 'command -v clang cmake ninja pkg-config >/dev/null' || { echo "FAIL: native toolchain (clang, cmake, ninja, pkg-config)"; exit 1; }
run 'pkg-config --exists gtk+-3.0 gstreamer-1.0 libsecret-1 ayatana-appindicator3-0.1' \
  || { echo "FAIL: pkg-config modules (gtk+-3.0, gstreamer-1.0, libsecret-1, ayatana-appindicator3-0.1)"; exit 1; }
if [ "$skip_build" != "--no-build" ]; then
  run 'cd /tmp && flutter create --platforms=linux -e t >/dev/null && cd t && flutter build linux --release >/dev/null && test -x build/linux/x64/release/bundle/t' \
    || { echo "FAIL: trivial Linux build with a swapped HOME"; exit 1; }
fi
echo "OK: $image"
