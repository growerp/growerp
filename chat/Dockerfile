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

FROM openjdk:11-jdk as build-env
MAINTAINER GrowERP <support@growerp.com>

ARG BRANCH=development # currently either master or development we need to add existing

RUN apt-get update && \
    apt-get install -y curl git wget zip unzip apt-transport-https && \
    apt-get clean

RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp /root/growerp
WORKDIR /root/growerp/chat
RUN ./gradlew build

FROM jetty
COPY --from=build-env /root/growerp/chat/build/libs/growerp-chat-0.0.2.war /var/lib/jetty/webapps/root.war
EXPOSE 8080
