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
#
# to be build from the flutter directory
# with: docker build --build-arg DOCKER_TAG=1.3.0 -f packages/admin/Dockerfile -t growerp/admin . --progress=plain
#
#Stage 1 - Install dependencies and build the app
# FROM growerp/flutter-sdk-image:latest
FROM ghcr.io/cirruslabs/flutter:stable

ARG BRANCH=master # currently either master or development we need to add existing
ARG DOCKER_TAG=1.0.0+1
USER root
# Install linux dependencies
RUN apt-get update && \
    apt-get install -y git zip gdb libstdc++6 \
    fonts-droid-fallback nano sed && \
    apt-get clean

# git security
RUN git config --system --add safe.directory '*'

# USER mobiledevops

# activate melos
# RUN dart pub global activate melos 3.4.0
# ENV PATH="$PATH":"$HOME/.pub-cache/bin"
# ENV FLUTTER_HOME="/home/mobiledevops/.flutter-sdk"
# ENV PATH="$PATH:$FLUTTER_HOME/bin"

# Pre-install Android SDK components to avoid runtime downloads
# Accept all licenses, install build-tools, platforms, NDK, and CMake upfront
# Versions must match what Flutter stable's Gradle build actually requests:
#   - flutter.ndkVersion -> 28.2.13676358
#   - flutter.compileSdkVersion -> 34 (and 36 for some packages)
RUN yes | sdkmanager --licenses && \
    sdkmanager "build-tools;35.0.0" \
    "platforms;android-34" "platforms;android-36" \
    "ndk;28.2.13676358" "cmake;3.22.1"

# Pre-cache Flutter artifacts for Android to avoid runtime downloads
RUN flutter precache --android

# Limit memory during Docker build: disable Gradle daemon, cap Dart VM heap
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx2g"
ENV DART_VM_OPTIONS="--old_gen_heap_size=1024"

# get growerp repos
#RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git /opt/growerp
#RUN cp /opt/growerp/flutter /home/mobiledevops/growerp
# copy from local below, two lines above from repository
COPY . /home/mobiledevops/growerp
WORKDIR /home/mobiledevops/growerp

# Clean up any corrupted pub cache and set up environment
RUN flutter pub cache repair && \
    dart pub global activate melos 3.4.0

ENV PATH="$PATH:/root/.pub-cache/bin"

# Bootstrap all packages with fresh dependencies
RUN /root/.pub-cache/bin/melos clean && \
    /root/.pub-cache/bin/melos bootstrap && \
    /root/.pub-cache/bin/melos build --no-select && \
    /root/.pub-cache/bin/melos l10n --no-select

# Configure app_settings.json files for automated testing (all example and app packages)
RUN find packages -name "app_settings.json" -type f -exec sed -i \
    -e 's|"databaseUrlDebug": "[^"]*"|"databaseUrlDebug": "http://moqui"|g' \
    -e 's|"chatUrlDebug": "[^"]*"|"chatUrlDebug": "ws://moqui"|g' {} \;

# Configure test files for automated testing
RUN sed -i -e 's/overrideUrl: null/overrideUrl: "http:\/\/moqui"/g' \
    packages/growerp_core/lib/src/domains/common/integration_test/common_test.dart

# VOLUME /home/mobiledevops/growerp/test


