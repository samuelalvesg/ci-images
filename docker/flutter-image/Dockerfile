# Flutter SDK image for web builds and Linux analyze/test (replaces ghcr.io/cirruslabs/flutter, which stopped at 3.44.0).
# Two consumers, one image:
#   - GitHub Actions: `container: image: ...`. The runner swaps HOME (/github/home) and checks the repo out as another
#     owner, so nothing here may depend on /root settings and git must trust any directory (system-level config).
#   - Coolify: `FROM` base of the app Dockerfile, pulled from ghcr.io (the package must be public to pull without login).
# Licensed under Apache-2.0 (see LICENSE). The Flutter SDK, Dart and the Ubuntu packages inside the image
# keep their own licenses; this license covers only the files in this directory.
FROM ubuntu:24.04

ARG FLUTTER_VERSION=3.47.5
ARG FLUTTER_CHANNEL=stable

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_ROOT=/sdks/flutter \
    PUB_CACHE=/root/.pub-cache \
    CI=true \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    DART_DISABLE_TELEMETRY=1
ENV PATH=${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/bin/cache/dart-sdk/bin:${PUB_CACHE}/bin:${PATH}

# build-essential/clang/cmake/pkg-config: native toolchain for cargokit and the Rust fallback in the app Dockerfile.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git jq unzip xz-utils zip \
        build-essential clang cmake ninja-build pkg-config libglu1-mesa python3 \
    && rm -rf /var/lib/apt/lists/*

# The archive hash comes from Google's release manifest and is checked before extraction, so a corrupted or
# swapped download fails the build instead of shipping.
RUN set -eu; \
    manifest=/tmp/releases_linux.json; \
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json -o "$manifest"; \
    archive=$(jq -r --arg v "$FLUTTER_VERSION" --arg c "$FLUTTER_CHANNEL" \
        '.releases[] | select(.version==$v and .channel==$c) | .archive' "$manifest" | head -n1); \
    sha=$(jq -r --arg v "$FLUTTER_VERSION" --arg c "$FLUTTER_CHANNEL" \
        '.releases[] | select(.version==$v and .channel==$c) | .sha256' "$manifest" | head -n1); \
    [ -n "$archive" ] && [ -n "$sha" ] || { echo "Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL) not in the release manifest" >&2; exit 1; }; \
    curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/$archive" -o /tmp/flutter.tar.xz; \
    echo "$sha  /tmp/flutter.tar.xz" | sha256sum -c -; \
    mkdir -p /sdks; tar -xJf /tmp/flutter.tar.xz -C /sdks; \
    rm -f /tmp/flutter.tar.xz "$manifest"; \
    git config --system --add safe.directory '*'; \
    flutter precache --web; \
    flutter --version

LABEL org.opencontainers.image.title="flutter" \
      org.opencontainers.image.description="Flutter SDK for web builds on Ubuntu 24.04" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/samuelalvesg/ci-images" \
      dev.flutter.version="${FLUTTER_VERSION}"

WORKDIR /app
