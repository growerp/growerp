#
# This software is in the public domain under CC0 1.0 Universal plus a
# Grant of Patent License.
# 
# To the extent possible under law, the author(s) have dedicated all
# copyright and related and neighboring rights to this software to the
# public domain worldwide. This software is distributed without any
# warranty.
# 
# You should have received a copy of the CC0 Public Domain Dedication
# along with this software (see the LICENSE.md file). If not, see
# <http://creativecommons.org/publicdomain/zero/1.0/>.
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
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git zip gdb libstdc++6 fonts-droid-fallback nano sed \
    xvfb libgtk-3-dev ninja-build cmake clang lld llvm pkg-config liblzma-dev \
    libglu1-mesa binutils && \
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
