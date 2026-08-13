#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Headless test runner image — runs Flutter integration tests on Linux desktop
# with xvfb for a virtual display. This replaces the previous Android-emulator
# approach, eliminating ADB, socat tunnels, and Gradle builds entirely.
#
# Build from the flutter/ directory:
#   docker build -f ci/Dockerfile -t growerp/flutter-test-runner:latest .
#
FROM ghcr.io/cirruslabs/flutter:stable

ARG BRANCH=master
USER root

# Install Linux desktop build dependencies and xvfb for headless display
# Enable universe repo (required on Ubuntu 24.04+ for cmake, gdb, clang, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git zip gdb libstdc++6 fonts-noto nano sed curl \
    xvfb libgtk-3-dev ninja-build cmake clang lld llvm pkgconf liblzma-dev \
    libglu1-mesa binutils \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Flutter's Linux build looks for tools (llvm-ar, ar, ld.lld) in /usr/lib/llvm-18/bin.
# Ensure they exist there by symlinking from system paths if missing.
RUN mkdir -p /usr/lib/llvm-18/bin && \
    for tool in ar llvm-ar ld.lld; do \
      if [ ! -f "/usr/lib/llvm-18/bin/$tool" ]; then \
        src=$(which "$tool" 2>/dev/null) && \
        [ -n "$src" ] && ln -sf "$src" "/usr/lib/llvm-18/bin/$tool"; \
      fi; \
    done

# git security
RUN git config --system --add safe.directory '*'

# Enable Linux desktop support
RUN flutter config --enable-linux-desktop

# Pre-cache Flutter artifacts for Linux desktop
RUN flutter precache --linux

# Limit memory during Docker build
ENV DART_VM_OPTIONS="--old_gen_heap_size=1024"

# Copy source and set workdir
COPY . /home/mobiledevops/growerp
WORKDIR /home/mobiledevops/growerp

# Clean up any corrupted pub cache and set up environment
RUN flutter pub cache repair && \
    dart pub global activate melos 7.4.0

ENV PATH="$PATH:/root/.pub-cache/bin"

# Bootstrap all packages with fresh dependencies
RUN /root/.pub-cache/bin/melos clean && \
    /root/.pub-cache/bin/melos bootstrap && \
    /root/.pub-cache/bin/melos build --no-select && \
    /root/.pub-cache/bin/melos l10n --no-select

# Vendor pdfium so the Linux desktop build never downloads it at cmake time.
# The printing plugin fetches pdfium from GitHub on every cmake configure, and
# every package depends on it via growerp_core — ~30 downloads per test job,
# with no retry, so a single hiccup fails a whole package with
# "Build step for pdfium failed: 1 / Unable to generate build files".
# The pub cache lives in the image (the workspace volume mount does not shadow
# it), so patching the cached plugin here holds for every test run.
RUN set -eux; \
    CMAKE_FILE=$(ls /root/.pub-cache/hosted/pub.dev/printing-*/linux/CMakeLists.txt); \
    PDFIUM_VERSION=$(sed -n 's/^set(PDFIUM_VERSION "\([0-9]*\)".*/\1/p' "$CMAKE_FILE"); \
    [ -n "$PDFIUM_VERSION" ]; \
    mkdir -p /opt/pdfium; \
    curl -fsSL -o /opt/pdfium/pdfium-linux-x64.tgz \
      "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/${PDFIUM_VERSION}/pdfium-linux-x64.tgz"; \
    sed -i 's|\${PDFIUM_URL}|/opt/pdfium/pdfium-linux-x64.tgz|' "$CMAKE_FILE"; \
    grep -q '/opt/pdfium/pdfium-linux-x64.tgz' "$CMAKE_FILE"

# No sed patching needed — backend URL is injected at test time via
# --dart-define=BACKEND_URL and --dart-define=CHAT_URL

# Make pub cache, flutter config, and workspace writable for any UID.
# The container runs as the host user (via HOST_UID/HOST_GID in compose)
# to avoid creating root-owned files on the mounted volume.
RUN chmod -R a+rw /root/.pub-cache && \
    chmod -R a+rw /root/.config 2>/dev/null || true && \
    chmod -R a+rw /home/mobiledevops && \
    chmod -R a+rw /sdks/flutter 2>/dev/null || true && \
    chmod a+rx /root && \
    chmod 1777 /tmp && \
    mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
