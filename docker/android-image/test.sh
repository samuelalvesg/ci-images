#!/usr/bin/env bash
# Smoke test for the flutter-android image: Java, SDK components, Rust targets and a real APK build of a trivial app.
# Usage: docker/android-image/test.sh <image> [--no-build]
set -euo pipefail
image="${1:?image}"; skip_build="${2:-}"
run() { docker run --rm -e HOME=/github/home "$image" bash -c "$1"; }

run 'java -version 2>&1 | grep -q "17\."' || { echo "FAIL: Java 17"; exit 1; }
run 'sdkmanager --list_installed 2>/dev/null | grep -E "platforms;android-36|build-tools;36.0.0|ndk;28.2.13676358" | wc -l | grep -q "^3$"' \
  || { echo "FAIL: SDK components (platform 36, build-tools 36.0.0, NDK 28.2.13676358)"; exit 1; }
run 'rustup target list --installed | grep -c android | grep -q "^4$"' || { echo "FAIL: Rust Android targets"; exit 1; }
run 'flutter doctor 2>&1 | grep -E "Android toolchain" | grep -q "\["' || { echo "FAIL: flutter doctor does not see the Android toolchain"; exit 1; }
if [ "$skip_build" != "--no-build" ]; then
  run 'cd /tmp && flutter create --platforms=android -e t >/dev/null && cd t && flutter build apk --debug --target-platform=android-arm64 >/dev/null && test -s build/app/outputs/flutter-apk/app-debug.apk' \
    || { echo "FAIL: trivial APK build with a swapped HOME"; exit 1; }
fi
echo "OK: $image"
