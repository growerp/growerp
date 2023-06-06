#stage 1 -get files and build
FROM openjdk:11-jdk as build-env
MAINTAINER Growerp <support@growerp.com>

ARG BRANCH=development # currently either master or development we need to add existing

RUN apt-get update && \
    apt-get install -y curl git wget zip unzip apt-transport-https && \
    apt-get clean
#install dart
RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list
RUN apt-get update && apt-get install dart
RUN export PATH="/usr/lib/dart/bin:$PATH"
#install growerp backend
RUN dart pub global activate growerp
ENV PATH="/root/.pub-cache/bin:$PATH"
# will install in /root/growerp/flutterDevelopment
RUN growerp install backend -dev -noBuild
# antwebsystems website
WORKDIR /root/growerp/moquiDevelopment/
RUN git clone --depth 1 https://github.com/AntWebsystems-Co-Ltd/vueWebsite.git /root/vueWebsite
RUN cp /root/vueWebsite/AWSSetupAaaWebSiteData.xml runtime/component/growerp/service/growerp
RUN cp /root/vueWebsite/WebSiteRestServices.xml runtime/component/growerp/data
# local db for development but need search
RUN echo $BRANCH
RUN if [ "$BRANCH" = "development" ]; then ./gradlew downloadElasticsearch ; fi
# production uses postgresql
RUN if [ "$BRANCH" = "master" ]; then curl -L https://jdbc.postgresql.org/download/postgresql-42.2.9.jar -o /runtime/lib ; fi 
RUN ./gradlew addRunTime
# unzip war file
WORKDIR /opt/moqui
RUN unzip -q /root/growerp/moquiDevelopment/moqui-plus-runtime.war

# stage 2 create image
FROM openjdk:11-jdk
RUN apt-get update && apt-get install -y apt-transport-https nano && apt-get clean
WORKDIR /opt
COPY --from=build-env /opt/moqui .
# exposed as volumes for configuration purposes
VOLUME ["/opt/moqui/runtime/conf", "/opt/moqui/runtime/lib", "/opt/moqui/runtime/classes", "/opt/moqui/runtime/ecomponent"]
# exposed as volumes to persist data outside the container, recommended
VOLUME ["/opt/moqui/runtime/log", "/opt/moqui/runtime/txlog", "/opt/moqui/runtime/sessions", "/opt/moqui/runtime/db", "/opt/moqui/runtime/elasticsearch"]

# Main Servlet Container Port
EXPOSE 80
# ElasticSearch HTTP Port
EXPOSE 9200
# ElasticSearch Cluster (TCP Transport) Port
EXPOSE 9300
# Hazelcast Cluster Port
EXPOSE 5701

# this is to run from the war file directly, preferred approach unzips war file in advance
# ENTRYPOINT ["java", "-jar", "moqui.war"]
ENTRYPOINT ["java", "-cp", ".", "MoquiStart", "port=80"]

HEALTHCHECK --interval=30s --timeout=600ms --start-period=120s CMD curl -f -H "X-Forwarded-Proto: https" -H "X-Forwarded-Ssl: on" http://localhost/status || exit 1
# specify this as a default parameter if none are specified with docker exec/run, ie run production by default
CMD ["conf=conf/MoquiProductionConf.xml"]

