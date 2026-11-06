#!/usr/bin/env bash
# Smoke test for the dotnet image. Usage: docker/dotnet-image/test.sh <image> <expected-major, e.g. 10>
set -euo pipefail
image="${1:?image}"; major="${2:?major}"
run() { docker run --rm -e HOME=/github/home "$image" bash -c "$1"; }
run "dotnet --version | grep -q '^$major\\.'" || { echo "FAIL: SDK is not $major.x"; exit 1; }
run 'dotnet-ef --version >/dev/null && python3 --version && jq --version' || { echo "FAIL: dotnet-ef/python3/jq"; exit 1; }
run 'cd /tmp && dotnet new console -n t -o t >/dev/null && cd t && dotnet build -v q >/dev/null' || { echo "FAIL: trivial build with swapped HOME"; exit 1; }
echo "OK: $image"
