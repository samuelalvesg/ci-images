# Rust toolchain image for CI: stable + a pinned nightly with wasm32 and rust-src (needed by the threaded wasm build of
# flutter_rust_bridge), plus flutter_rust_bridge_codegen and wasm-pack installed once instead of on every CI run.
# `BASE` makes the same file produce two images:
#   - rust:         BASE=ubuntu:24.04 (default), for Rust-only repositories
#   - flutter-rust: BASE=ghcr.io/samuelalvesg/flutter:<version>, the full web build chain (Flutter + Rust)
# Licensed under Apache-2.0 (see LICENSE); the toolchains inside keep their own licenses.
# The default base is pinned by digest (Dependabot proposes digest updates of the same tag).
ARG BASE=ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852
FROM ${BASE}

# A fixed Rust version, so rebuilding the image does not silently change the compiler. Raise it on purpose.
ARG RUST_STABLE=1.99.1
ARG RUST_NIGHTLY=nightly-2026-06-01
ARG FRB_VERSION=2.13.0
ARG WASM_PACK_VERSION=0.14.0
# Extra tools for building a Flutter app (flutter-rust image): wasm-opt and protoc + protoc_plugin.
ARG WITH_APP_TOOLS=false
ARG PROTOC_PLUGIN_VERSION=21.1.2

# System-wide locations: GitHub Actions swaps HOME, so nothing may live under /root or $HOME.
ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    CARGO_TERM_COLOR=always
ENV PATH=/usr/local/cargo/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git build-essential clang cmake pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'

# The installers are downloaded to a file and then run (no `curl | sh`): a failed download stops the build instead of
# running an empty script.
RUN set -eu; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain "$RUST_STABLE" -c clippy -c rustfmt; \
    rustup toolchain install "$RUST_NIGHTLY" --profile minimal -c rust-src -t wasm32-unknown-unknown; \
    rustup target add wasm32-unknown-unknown; \
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh -o /tmp/binstall.sh; \
    bash /tmp/binstall.sh; \
    rm -f /tmp/rustup-init.sh /tmp/binstall.sh; \
    cargo binstall -y "flutter_rust_bridge_codegen@$FRB_VERSION" "wasm-pack@$WASM_PACK_VERSION"; \
    chmod -R a+rwX "$RUSTUP_HOME" "$CARGO_HOME"; \
    rustc --version; rustc +"$RUST_NIGHTLY" --version; flutter_rust_bridge_codegen --version; wasm-pack --version

# wasm-opt (binaryen) is used by wasm-pack, which otherwise downloads it on every run.
# protoc_plugin is pinned to the line that matches protobuf ^3.1.0 used by the app's gRPC client.
RUN set -eu; [ "$WITH_APP_TOOLS" = "true" ] || exit 0; \
    apt-get update && apt-get install -y --no-install-recommends binaryen protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*; \
    dart pub global activate protoc_plugin "${PROTOC_PLUGIN_VERSION}"; \
    chmod -R a+rwX "$PUB_CACHE"; \
    protoc --version; wasm-opt --version; command -v protoc-gen-dart

LABEL org.opencontainers.image.licenses="Apache-2.0" \
      dev.rust.stable="${RUST_STABLE}" \
      dev.rust.nightly="${RUST_NIGHTLY}" \
      dev.frb.version="${FRB_VERSION}"
