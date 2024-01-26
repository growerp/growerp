ARG DOCKER_REGISTRY
FROM ${DOCKER_REGISTRY}/avito/debian-minbase:9.13

ARG ARTIFACTORY_URL
ARG SDK_VERSION
ARG EMULATOR_ARCH

# -------------------- Common -------------------
# net-tools             basic network primitives
# socat                 redirecting adb and VNC from emulator to host
# libglu1               emulators software rendering
# libpulse0, libx...    qemu x64 startup (API 30)
# lib32stdc++6          mksdcard android sdk tool
RUN apt-get update && \
	apt-get install --no-install-recommends -y \
	        curl \
    	    unzip \
    	    openjdk-11-jdk && \
    apt-get install -y \
            net-tools \
            socat \
            libglu1 \
            libpulse0 \
            libx11-6 libxcb1 libxdamage1 libnss3 libxcomposite1 libxcursor1 libxi6 libxext6 libxfixes3 \
            lib32stdc++6 && \
    apt-get clean && apt-get purge

ARG ANDROID_HOME=/opt/android-sdk

# DEBIAN_FRONTEND - to prevent timezone questions
ENV LANG=C.UTF-8 \
    SHELL=/bin/bash \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    DEBIAN_FRONTEND=noninteractive \
    VERSION=${SDK_VERSION} \
    ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ANDROID_HOME}/emulator/lib64/qt/lib:${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/gles_swiftshader
# -----------------------------------------------

# ----------------- Android SDK -----------------
# https://developer.android.com/studio/index.html#command-tools
# Additional info about directory structure: https://stackoverflow.com/a/61176718/981330
ARG ANDROID_SDK_BASE_URL=${ARTIFACTORY_URL}android-build-env/android_sdk

COPY unzip_from_url.sh /usr/local/bin/unzip_from_url.sh

RUN unzip_from_url.sh ${ANDROID_SDK_BASE_URL}/cmdline-tools/cmdline-tools-linux_6_0.zip $ANDROID_HOME && \
    unzip_from_url.sh ${ANDROID_SDK_BASE_URL}/platforms/platforms_31_0_1.zip $ANDROID_HOME && \
    unzip_from_url.sh ${ANDROID_SDK_BASE_URL}/emulator/emulator_linux_31_2_8.zip $ANDROID_HOME && \
    unzip_from_url.sh ${ANDROID_SDK_BASE_URL}/platform-tools/platform-tools_linux_33_0_0.zip $ANDROID_HOME && \
    unzip_from_url.sh ${ANDROID_SDK_BASE_URL}/tools/tools_linux_26_1_1.zip $ANDROID_HOME && \
    unzip_from_url.sh "${ANDROID_SDK_BASE_URL}/system-images/system-images-android-${SDK_VERSION}-${EMULATOR_ARCH}.zip" $ANDROID_HOME && \
    rm /usr/local/bin/unzip_from_url.sh

# ------------------ Emulators ------------------
# Create emulator and increase internal storage
RUN echo "no" | avdmanager create avd \
    --name emulator_${SDK_VERSION} \
    --package "system-images;android-${SDK_VERSION};google_apis;${EMULATOR_ARCH}" \
    --abi google_apis/${EMULATOR_ARCH} && \
    mksdcard -l e 512M /sdcard.img

COPY hardware/config_${SDK_VERSION}.ini /root/.android/avd/emulator_${SDK_VERSION}.avd/config.ini
# -----------------------------------------------

# ----------------- Entrypoint ------------------
COPY prepare_snapshot.sh adb_redirect.sh run_emulator.sh entrypoint.sh /

# https://developer.android.com/studio/command-line/adb#howadbworks
# 5037 - ADB server port
# 5554 - Console port
# 5555 - ADB
# 5900 - VNC
EXPOSE 5037 5554 5555 5900

CMD ["/entrypoint.sh"]
