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
# GrowERP Dockerfile — builds Flutter web apps and Moqui 4 backend.
# Located at repository root; build context is the repo root.
#
# Build:  docker build -t growerp/growerp-moqui .
# Or via docker-compose from the docker/ directory

# ===== Stage 1: Build Flutter web applications =====
FROM ghcr.io/cirruslabs/flutter:stable AS build-flutter

ARG BRANCH=moqui4
USER root

# Install linux dependencies
RUN apt-get update && \
    apt-get install -y git zip gdb libstdc++6 \
    fonts-droid-fallback nano sed && \
    apt-get clean

# git security
RUN git config --system --add safe.directory '*'

# activate melos
RUN dart pub global activate melos
ENV PATH="$PATH:/root/.pub-cache/bin"

# Clone growerp repo (shallow — submodules not needed for Flutter build)
WORKDIR /root
RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git

WORKDIR /root/growerp/flutter
RUN sed -i 's\//webactivate \\' packages/admin/lib/main.dart
# Clean any existing dart tool caches
RUN find . -name ".dart_tool" -type d -exec rm -rf {} + 2>/dev/null || true
RUN melos clean
RUN melos bootstrap
# localization
RUN melos l10n --no-select
# build generated code (freezed, retrofit, etc.)
RUN melos build --no-select
# build Flutter web apps
WORKDIR /root/growerp/flutter/packages/admin
RUN flutter build web --release --wasm
WORKDIR /root/growerp/flutter/packages/assessment
RUN flutter build web --release --wasm

# ===== Stage 2: Build Moqui 4 backend =====
FROM eclipse-temurin:21-jdk AS build-env
ARG BRANCH=moqui4
ARG DOCKER_TAG=NOTSET1

RUN echo "DockerTag version: $DOCKER_TAG"

RUN apt-get update && \
    apt-get install -y curl git wget zip unzip apt-transport-https perl && \
    apt-get clean

RUN git config --system --add safe.directory '*'
# Rewrite all SSH git URLs to HTTPS globally so submodule clones work without SSH keys
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# Clone GrowERP repo and initialise all submodules (moqui -> runtime -> mantle-udm/usl/moqui-fop)
WORKDIR /root
RUN git clone -b $BRANCH https://github.com/growerp/growerp.git
WORKDIR /root/growerp
RUN git submodule update --init --recursive
# Create symlinks for custom components (backend, pop-rest-store, mantle-stripe)
RUN bash setup-backend.sh

# AntWebsystems website
ARG PAT
RUN git clone --depth 1 https://$PAT@github.com/AntWebsystems-Co-Ltd/vueWebsite.git /root/vueWebsite
RUN cp /root/vueWebsite/AWSSetupAaaWebSiteData.xml moqui/runtime/component/growerp/data
RUN mkdir -p moqui/runtime/component/growerp/service/growerp/website
RUN cp /root/vueWebsite/WebSiteRestServices.xml moqui/runtime/component/growerp/service/growerp/website

# Copy Flutter web build artifacts from stage 1 into PopRestStore
# (write to pop-rest-store directly, which is sym-linked as PopRestStore)
COPY --from=build-flutter /root/growerp/flutter/packages/admin/build/web \
    /root/growerp/pop-rest-store/screen/store/admin
COPY --from=build-flutter /root/growerp/flutter/packages/assessment/build/web \
    /root/growerp/pop-rest-store/screen/store/assessment

# Fix the base href in index.html to work with sub-paths
WORKDIR /root/growerp/pop-rest-store/screen/store
RUN sed -i 's|<base href="/">|<base href="/admin/">|g' "admin/index.html"
RUN sed -i 's|<base href="/">|<base href="/assessment/">|g' "assessment/index.html"
# Remove service worker registration from index.html (registered in root.html.ftl)
RUN perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "admin/index.html"
RUN perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "assessment/index.html"

# Download PostgreSQL JDBC driver
WORKDIR /root/growerp/moqui
RUN curl -L https://jdbc.postgresql.org/download/postgresql-42.7.3.jar \
    -o runtime/lib/postgresql-42.7.3.jar

# Remove submodule .git gitlink files — Grgit/JGit cannot resolve them and
# the build only uses them for optional version embedding in the war file.
RUN rm -f .git && \
    rm -f runtime/.git && \
    find runtime/component -maxdepth 2 -name .git -type f -delete

# Build Moqui system (produces moqui-plus-runtime.war)
RUN ./gradlew addRunTime

# Resolve absolute symlinks to real copies so COPY --from works in the final stage
RUN for link in runtime/component/growerp runtime/component/PopRestStore runtime/component/mantle-stripe; do \
    if [ -L "$link" ]; then \
    target=$(readlink -f "$link") && rm "$link" && cp -a "$target" "$link"; \
    fi; \
    done

# Unzip war file to final location
WORKDIR /opt/moqui
RUN unzip -q /root/growerp/moqui/moqui-plus-runtime.war

# ===== Stage 3: Create runtime image =====
FROM eclipse-temurin:21-jdk
ARG DOCKER_TAG=NOTSET1

RUN apt-get update && apt-get install -y apt-transport-https nano curl && apt-get clean

COPY --from=build-env /opt/moqui /opt/moqui
# The war already contains a partial runtime copy; remove it so the full source
# runtime (with resolved symlinks for growerp, PopRestStore, mantle-stripe) can
# be copied cleanly without directory/file conflicts.
RUN rm -rf /opt/moqui/runtime
COPY --from=build-env /root/growerp/moqui/runtime /opt/moqui/runtime

# exposed as volumes for configuration purposes
VOLUME ["/opt/moqui/runtime/conf", "/opt/moqui/runtime/lib", "/opt/moqui/runtime/classes", "/opt/moqui/runtime/component"]
# exposed as volumes to persist data outside the container, recommended
VOLUME ["/opt/moqui/runtime/log", "/opt/moqui/runtime/txlog", "/opt/moqui/runtime/sessions", "/opt/moqui/runtime/db", "/opt/moqui/runtime/elasticsearch"]

# Main Servlet Container Port
EXPOSE 80

RUN cp /opt/moqui/runtime/component/growerp/deploy/initstart.sh /opt/moqui/initstart.sh
WORKDIR /opt/moqui
RUN echo "=========$DOCKER_TAG"

HEALTHCHECK --interval=30s --timeout=600ms --start-period=120s CMD curl -f -H "X-Forwarded-Proto: https" -H "X-Forwarded-Ssl: on" http://localhost/status || exit 1

# Save ARG as ENV for the CMD
ENV TAG=$DOCKER_TAG
CMD ["sh", "-c", "./initstart.sh ${TAG}"]
