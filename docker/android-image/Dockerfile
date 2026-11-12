# Android toolchain on top of the flutter-rust image: JDK 17, Android SDK (command-line tools, platform, build-tools, NDK)
# and the Rust Android targets, so `flutter build apk/appbundle` needs no setup step in CI.
# The SDK, Gradle cache and Java live in system paths: GitHub Actions swaps HOME, so nothing may depend on /root or $HOME.
# Licensed under Apache-2.0 (see LICENSE); the Android SDK (Android Software Development Kit License), the JDK and the
# Ubuntu packages keep their own licenses. Building with this image means you accept the Android SDK licenses.
ARG BASE=ghcr.io/samuelalvesg/flutter-rust:3.50.0
FROM ${BASE}

ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358
# Versions the app builds with (apps/symmetris/android): they decide which Gradle distribution and plugins are baked below.
ARG GRADLE_VERSION=8.14
ARG AGP_VERSION=8.11.1
ARG KOTLIN_VERSION=2.2.20
ARG PREWARM_GRADLE=true

ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    GRADLE_USER_HOME=/opt/gradle-home
ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# The command-line tools archive is checked against the sha1 in Google's repository manifest before extraction.
# `yes | sdkmanager --licenses` is the documented way to accept the licenses; with pipefail the SIGPIPE that `yes` gets when
# sdkmanager stops reading would fail the build, hence the ignore.
# hadolint ignore=DL4006
RUN set -eu; \
    file="commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip"; \
    curl -fsSL https://dl.google.com/android/repository/repository2-3.xml -o /tmp/repository.xml; \
    sha1=$(python3 -c "import re,sys; m=re.search(r'<checksum type=\"sha1\">([0-9a-f]{40})</checksum>\s*<url>${file}</url>', open('/tmp/repository.xml').read()); sys.exit('not in the repository manifest') if not m else print(m.group(1))"); \
    curl -fsSL "https://dl.google.com/android/repository/${file}" -o /tmp/cmdline.zip; \
    printf '%s  %s\n' "${sha1}" /tmp/cmdline.zip > /tmp/cmdline.sha1; \
    sha1sum -c /tmp/cmdline.sha1; \
    mkdir -p "${ANDROID_HOME}/cmdline-tools"; \
    unzip -q /tmp/cmdline.zip -d /tmp/cmdline; \
    mv /tmp/cmdline/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest"; \
    rm -rf /tmp/cmdline /tmp/cmdline.zip /tmp/cmdline.sha1 /tmp/repository.xml; \
    yes | sdkmanager --licenses >/dev/null; \
    sdkmanager "platform-tools" "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "ndk;${ANDROID_NDK}" >/dev/null; \
    mkdir -p "${GRADLE_USER_HOME}"; \
    chmod -R a+rwX "${ANDROID_HOME}" "${GRADLE_USER_HOME}"

# cargokit builds the native library with the stable toolchain for the four Android ABIs.
# No chmod -R on RUSTUP_HOME or the Flutter SDK here: changing the mode of an existing tree copies all of it into a new layer
# (it doubled the size of this image), and CI jobs run as root.
RUN rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# hadolint ignore=DL4006
RUN flutter config --android-sdk "${ANDROID_HOME}" >/dev/null \
    && (yes | flutter doctor --android-licenses >/dev/null 2>&1 || true)

# Bakes the Gradle distribution, the Android Gradle Plugin, the Kotlin plugin and the Flutter engine artifacts for the
# versions above into GRADLE_USER_HOME and the Flutter cache, so a CI build does not download them (that download is most
# of the time of a cold Gradle build). It uses the app's versions on purpose: the Flutter 3.47.5 template uses Gradle 9.3.1,
# AGP 9.1.0 and Kotlin 2.4.0, which would not help an app on other versions. Set PREWARM_GRADLE=false to skip it.
# The cd is into a throwaway project that is deleted in the same instruction, so WORKDIR does not apply.
# hadolint ignore=DL3003
RUN set -eu; [ "$PREWARM_GRADLE" = "true" ] || exit 0; \
    cd /tmp && flutter create --platforms=android -e warm >/dev/null; \
    cd /tmp/warm/android; \
    sed -i "s#gradle-[0-9.]*-all.zip#gradle-${GRADLE_VERSION}-all.zip#" gradle/wrapper/gradle-wrapper.properties; \
    sed -i -E 's/(com\.android\.application"\) version ")[0-9.]+/\1'"${AGP_VERSION}"'/; s/(org\.jetbrains\.kotlin\.android"\) version ")[0-9.]+/\1'"${KOTLIN_VERSION}"'/' settings.gradle.kts; \
    grep -q "application\") version \"${AGP_VERSION}\"" settings.gradle.kts; \
    grep -q "kotlin.android\") version \"${KOTLIN_VERSION}\"" settings.gradle.kts; \
    sed -i -E 's#-Xmx8G#-Xmx4G#; s#MaxMetaspaceSize=4G#MaxMetaspaceSize=1G#' gradle.properties; \
    cd /tmp/warm; \
    flutter build apk --release --target-platform=android-arm64 >/dev/null; \
    flutter build apk --debug --target-platform=android-arm64 >/dev/null; \
    (cd android && ./gradlew --stop >/dev/null 2>&1 || true); \
    cd /; rm -rf /tmp/warm

LABEL org.opencontainers.image.licenses="Apache-2.0" \
      dev.android.platform="${ANDROID_PLATFORM}" \
      dev.android.build-tools="${ANDROID_BUILD_TOOLS}" \
      dev.android.ndk="${ANDROID_NDK}" \
      dev.java.version="17"
