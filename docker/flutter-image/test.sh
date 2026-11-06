#!/usr/bin/env bash
# Smoke test for the image: expected Flutter version, web enabled, a trivial web build works.
# Usage: docker/flutter-image/test.sh <image> <expected-flutter-version>
set -euo pipefail
image="${1:?image}"; expected="${2:?expected flutter version}"
run() { docker run --rm "$image" bash -c "$1"; }

out=$(run 'flutter --version --machine')
echo "$out" | jq -e --arg v "$expected" '.frameworkVersion == $v' >/dev/null \
  || { echo "FAIL: frameworkVersion != $expected"; echo "$out" | jq -r .frameworkVersion; exit 1; }

run 'command -v cc >/dev/null && command -v git >/dev/null && command -v jq >/dev/null' \
  || { echo "FAIL: toolchain missing"; exit 1; }

run 'cd /tmp && flutter create --platforms=web -e t >/dev/null && cd t && flutter build web --release >/dev/null && test -s build/web/index.html' \
  || { echo "FAIL: trivial web build"; exit 1; }
# GitHub Actions container jobs: HOME is replaced and the checkout is owned by another uid.
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
git -C "$work" init -q
docker run --rm -e HOME=/github/home -v "$work:/w" -w /w "$image" bash -c 'git status >/dev/null && flutter --version >/dev/null' \
  || { echo "FAIL: not usable as a GitHub Actions container (HOME swap / repo owned by another uid)"; exit 1; }

echo "OK: $image has Flutter $expected, builds web and works as a CI container"
