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
# to be build from any directory

#Stage 1 - Install dependencies and build the app
FROM ghcr.io/cirruslabs/flutter:stable AS build-flutter

ARG BRANCH=master # currently either master or development we need to add existing
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

# get growerp repos
WORKDIR /root
RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git
WORKDIR /root/growerp/flutter
RUN echo "pwd: $PWD"
RUN sed -i 's\//webactivate \\' packages/admin/lib/main.dart
# Clean any existing dart tool caches
RUN find . -name ".dart_tool" -type d -exec rm -rf {} + 2>/dev/null || true
RUN melos clean
RUN melos bootstrap
# localization
RUN melos l10n --no-select
# build
RUN melos build --no-select
# build flutter app
WORKDIR /root/growerp/flutter/packages/admin
RUN flutter build web --release --wasm
WORKDIR /root/growerp/flutter/packages/assessment
RUN flutter build web --release --wasm

#stage 2 -get files and build
FROM eclipse-temurin:11-jdk AS build-env
ARG DOCKER_TAG=NOTSET1

RUN echo "DockerTag version: $DOCKER_TAG"
RUN echo "Pat: $PAT"

RUN apt-get update && \
    apt-get install -y curl git wget zip unzip apt-transport-https perl && \
    apt-get clean
#RUN git clone --depth 1 https://github.com/growerp/growerp.git /root/growerp
COPY --from=build-flutter /root/growerp /root/growerp
WORKDIR /root/growerp/moqui/runtime/component/PopRestStore/screen/store
# Copy Flutter web build files
RUN echo -e "Copying Flutter web files..."
RUN cp -r /root/growerp/flutter/packages/admin/build/web admin
RUN cp -r /root/growerp/flutter/packages/assessment/build/web assessment
# Fix the base href in index.html to work with path
RUN echo -e "Fixing base href in index.html..."
RUN  sed -i 's|<base href="/">|<base href="/admin/">|g' "admin/index.html"
RUN  sed -i 's|<base href="/">|<base href="/assessment/">|g' "assessment/index.html"
# Remove service worker registration from index.html (it's registered in root.html.ftl)
RUN perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "admin/index.html"
RUN perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "assessment/index.html"

WORKDIR /root/growerp/moqui
RUN git clone --depth 1 https://$PAT@github.com/AntWebsystems-Co-Ltd/vueWebsite.git /root/vueWebsite
# antwebsystems website TODO: need to be removed
RUN cp /root/vueWebsite/AWSSetupAaaWebSiteData.xml runtime/component/growerp/data
RUN mkdir runtime/component/growerp/service/growerp/website
RUN cp /root/vueWebsite/WebSiteRestServices.xml runtime/component/growerp/service/growerp/website
# Postgresql driver
RUN curl -L https://jdbc.postgresql.org/download/postgresql-42.7.3.jar -o runtime/lib/postgresql-42.7.3.jar
# elasticsearch
# RUN ./gradlew downloadel
# build Moqui system
RUN ./gradlew addRunTime
# unzip war file
WORKDIR /opt/moqui
RUN unzip -q /root/growerp/moqui/moqui-plus-runtime.war
# stage 2 create image
FROM eclipse-temurin:11-jdk
ARG DOCKER_TAG=NOTSET1
RUN apt-get update && apt-get install -y apt-transport-https nano && apt-get clean
COPY --from=build-env /opt/moqui /opt/moqui
COPY --from=build-env /root/growerp/moqui/runtime /opt/moqui/runtime
# exposed as volumes for configuration purposes
VOLUME ["/opt/moqui/runtime/conf", "/opt/moqui/runtime/lib", "/opt/moqui/runtime/classes", "/opt/moqui/runtime/component"]
# exposed as volumes to persist data outside the container, recommended
VOLUME ["/opt/moqui/runtime/log", "/opt/moqui/runtime/txlog", "/opt/moqui/runtime/sessions", "/opt/moqui/runtime/db", "/opt/moqui/runtime/elasticsearch"]

# Main Servlet Container Port
EXPOSE 80
# ElasticSearch HTTP Port
# EXPOSE 9200
# ElasticSearch Cluster (TCP Transport) Port
# EXPOSE 9300
# Hazelcast Cluster Port
# EXPOSE 5701

# this is to run from the war file directly, preferred approach unzips war file in advance
# ENTRYPOINT ["java", "-jar", "moqui.war"]
RUN cp /opt/moqui/runtime/component/growerp/deploy/initstart.sh /opt/moqui/initstart.sh
WORKDIR /opt/moqui
RUN echo "=========$DOCKER_TAG"
#ENTRYPOINT ["java", "-cp", ".", "MoquiStart", "port=80"]

HEALTHCHECK --interval=30s --timeout=600ms --start-period=120s CMD curl -f -H "X-Forwarded-Proto: https" -H "X-Forwarded-Ssl: on" http://localhost/status || exit 1
# specify this as a default parameter if none are specified with docker exec/run, ie run production by default
# Add an env to save ARG
ENV TAG=$DOCKER_TAG
CMD ./initstart.sh ${TAG}

