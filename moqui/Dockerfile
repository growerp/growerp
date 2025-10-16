#stage 1 -get files and build
ARG DOCKER_TAG=NOTSET1
FROM openjdk:11-jdk AS build-env

ARG BRANCH=development # currently either master or development we need to add existing
ARG DOCKER_TAG=NOTSET1
ARG PAT=NOTSET2

RUN echo "DockerTag version: $DOCKER_TAG"
RUN echo "Pat: $PAT"

RUN apt-get update && \
    apt-get install -y curl git wget zip unzip apt-transport-https xz-utils && \
    apt-get clean

# Install Flutter SDK
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
    tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt && \
    rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter config --no-analytics && \
    flutter precache --web && \
    dart pub global activate melos
#RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git /root/growerp
# build from the moqui directory instead of repository for debugging
COPY . /root/growerp/moqui

# Copy Flutter workspace for admin app build
COPY ../flutter /root/growerp/flutter

# delete debug user now replaced with system support
# RUN rm /root/growerp/moqui/runtime/component/growerp/data/0-GrowerpDebug.xml
RUN git clone --depth 1 https://$PAT@github.com/AntWebsystems-Co-Ltd/vueWebsite.git /root/vueWebsite

# Build Flutter Admin Web App
WORKDIR /root/growerp/flutter
ENV PATH="${PATH}:/root/.pub-cache/bin"
RUN melos clean && \
    melos bootstrap && \
    melos l10n --no-select && \
    melos build --no-select

WORKDIR /root/growerp/flutter/packages/admin
RUN sed -i 's/version: .*/version: '"${DOCKER_TAG}"'/' pubspec.yaml && \
    flutter build web --release

# antwebsystems website TODO: need to be removed
WORKDIR /root/growerp/moqui
RUN cp /root/vueWebsite/AWSSetupAaaWebSiteData.xml runtime/component/growerp/data
RUN mkdir runtime/component/growerp/service/growerp/website
RUN cp /root/vueWebsite/WebSiteRestServices.xml runtime/component/growerp/service/growerp/website
# Postgresql driver
RUN curl -L https://jdbc.postgresql.org/download/postgresql-42.2.9.jar -o runtime/lib/postgresql-42.2.9.jar
# elasticsearch
# RUN ./gradlew downloadel
# build Moqui system
RUN ./gradlew addRunTime

# Deploy Flutter Admin Web App to Moqui
COPY deploy-flutter-admin.sh /tmp/deploy-flutter-admin.sh
RUN chmod +x /tmp/deploy-flutter-admin.sh && \
    /tmp/deploy-flutter-admin.sh && \
    rm /tmp/deploy-flutter-admin.sh

# unzip war file
WORKDIR /opt/moqui
RUN unzip -q /root/growerp/moqui/moqui-plus-runtime.war
# stage 2 create image
FROM openjdk:11-jdk
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

