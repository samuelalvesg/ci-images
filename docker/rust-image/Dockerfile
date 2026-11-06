# Rust toolchain image for CI: stable + a pinned nightly with wasm32 and rust-src (needed by the threaded wasm build of
# flutter_rust_bridge), plus flutter_rust_bridge_codegen and wasm-pack installed once instead of on every CI run.
# `BASE` makes the same file produce two images:
#   - rust:         BASE=ubuntu:24.04 (default), for Rust-only repositories
#   - flutter-rust: BASE=ghcr.io/<owner>/flutter:<version>, the full web build chain (Flutter + Rust)
# Licensed under Apache-2.0 (see LICENSE); the toolchains inside keep their own licenses.
ARG BASE=ubuntu:24.04
FROM ${BASE}

ARG RUST_STABLE=stable
ARG RUST_NIGHTLY=nightly-2026-06-01
ARG FRB_VERSION=2.12.0
ARG WASM_PACK_VERSION=0.14.0

# System-wide locations: GitHub Actions swaps HOME, so nothing may live under /root or $HOME.
ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    CARGO_TERM_COLOR=always
ENV PATH=/usr/local/cargo/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git build-essential clang cmake pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "$RUST_STABLE" \
        -c clippy -c rustfmt; \
    rustup toolchain install "$RUST_NIGHTLY" --profile minimal -c rust-src -t wasm32-unknown-unknown; \
    rustup target add wasm32-unknown-unknown; \
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash; \
    cargo binstall -y "flutter_rust_bridge_codegen@$FRB_VERSION" "wasm-pack@$WASM_PACK_VERSION"; \
    chmod -R a+rwX "$RUSTUP_HOME" "$CARGO_HOME"; \
    rustc --version; rustc +"$RUST_NIGHTLY" --version; flutter_rust_bridge_codegen --version; wasm-pack --version

LABEL org.opencontainers.image.licenses="Apache-2.0" \
      dev.rust.stable="${RUST_STABLE}" \
      dev.rust.nightly="${RUST_NIGHTLY}" \
      dev.frb.version="${FRB_VERSION}"
