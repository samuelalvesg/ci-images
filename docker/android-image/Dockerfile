# Android toolchain on top of the flutter-rust image: JDK 17, Android SDK (command-line tools, platform, build-tools, NDK)
# and the Rust Android targets, so `flutter build apk/appbundle` needs no setup step in CI.
# The SDK, Gradle cache and Java live in system paths: GitHub Actions swaps HOME, so nothing may depend on /root or $HOME.
# Licensed under Apache-2.0 (see LICENSE); the Android SDK (Android Software Development Kit License), the JDK and the
# Ubuntu packages keep their own licenses. Building with this image means you accept the Android SDK licenses.
ARG BASE=ghcr.io/samuelalvesg/flutter-rust:3.47.5
FROM ${BASE}

ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358

ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    GRADLE_USER_HOME=/opt/gradle-home
ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# The command-line tools archive is checked against the sha1 in Google's repository manifest before extraction.
RUN set -eu; \
    file="commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip"; \
    curl -fsSL https://dl.google.com/android/repository/repository2-3.xml -o /tmp/repository.xml; \
    sha1=$(python3 -c "import re,sys; m=re.search(r'<checksum type=\"sha1\">([0-9a-f]{40})</checksum>\s*<url>${file}</url>', open('/tmp/repository.xml').read()); sys.exit('not in the repository manifest') if not m else print(m.group(1))"); \
    curl -fsSL "https://dl.google.com/android/repository/${file}" -o /tmp/cmdline.zip; \
    echo "${sha1}  /tmp/cmdline.zip" | sha1sum -c -; \
    mkdir -p "${ANDROID_HOME}/cmdline-tools"; \
    unzip -q /tmp/cmdline.zip -d /tmp/cmdline; \
    mv /tmp/cmdline/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest"; \
    rm -rf /tmp/cmdline /tmp/cmdline.zip /tmp/repository.xml; \
    yes | sdkmanager --licenses >/dev/null; \
    sdkmanager "platform-tools" "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "ndk;${ANDROID_NDK}" >/dev/null; \
    mkdir -p "${GRADLE_USER_HOME}"; \
    chmod -R a+rwX "${ANDROID_HOME}" "${GRADLE_USER_HOME}" /sdks/flutter 2>/dev/null || true

# cargokit builds the native library with the stable toolchain for the four Android ABIs.
RUN rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android \
    && chmod -R a+rwX "${RUSTUP_HOME}"

RUN flutter config --android-sdk "${ANDROID_HOME}" >/dev/null \
    && (yes | flutter doctor --android-licenses >/dev/null 2>&1 || true)

LABEL org.opencontainers.image.licenses="Apache-2.0" \
      dev.android.platform="${ANDROID_PLATFORM}" \
      dev.android.build-tools="${ANDROID_BUILD_TOOLS}" \
      dev.android.ndk="${ANDROID_NDK}" \
      dev.java.version="17"
