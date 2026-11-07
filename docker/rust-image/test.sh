#!/usr/bin/env bash
# Smoke test for the rust / flutter-rust images.
# Usage: docker/rust-image/test.sh <image> [flutter]   (pass "flutter" for the flutter-rust image)
set -euo pipefail
image="${1:?image}"; mode="${2:-}"
run() { docker run --rm -e HOME=/github/home "$image" bash -c "$1"; }

run 'rustc --version && cargo --version && cargo clippy --version && rustfmt --version' || { echo "FAIL: stable toolchain"; exit 1; }
run 'n=$(rustup toolchain list | grep nightly | cut -d" " -f1); rustup target list --installed --toolchain "$n" | grep -q wasm32-unknown-unknown' \
  || { echo "FAIL: nightly + wasm32 target"; exit 1; }
run 'flutter_rust_bridge_codegen --version && wasm-pack --version' || { echo "FAIL: FRB/wasm-pack"; exit 1; }
# The codegen must be the version the image says it is (label dev.frb.version), the one the apps pin in pubspec.yaml and Cargo.toml.
frb_expected="$(docker image inspect --format '{{ index .Config.Labels "dev.frb.version" }}' "$image")"
run "flutter_rust_bridge_codegen --version | grep -qw '$frb_expected'" || { echo "FAIL: flutter_rust_bridge_codegen is not $frb_expected"; exit 1; }
run 'cd /tmp && cargo new --lib t -q && cd t && cargo build -q' || { echo "FAIL: trivial cargo build with swapped HOME"; exit 1; }
# GitHub Actions checks the repository out as another user: git must not refuse it as "dubious ownership".
run 'mkdir /t && git init -q /t && chown -R 1234:1234 /t && cd /t && git status --short >/dev/null' \
  || { echo "FAIL: git rejects a repository owned by another user"; exit 1; }
if [ "$mode" = "flutter" ]; then
  run 'flutter --version >/dev/null && command -v rustc >/dev/null' || { echo "FAIL: flutter missing in flutter-rust"; exit 1; }
  run 'wasm-opt --version && protoc --version && command -v protoc-gen-dart' || { echo "FAIL: wasm-opt/protoc/protoc-gen-dart"; exit 1; }
fi
echo "OK: $image"
