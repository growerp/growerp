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
FROM growerp/flutter-sdk-image:3.16.9

ARG BRANCH=master # currently either master or development we need to add existing
ARG DOCKER_TAG=1.0.0+1
USER root
# Install linux dependencies
RUN apt-get update && \
    apt-get install -y git zip libgconf-2-4 gdb libstdc++6 \
    fonts-droid-fallback nano sed && \
    apt-get clean

# git security
RUN git config --system --add safe.directory '*'
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

USER mobiledevops

# activate melos
RUN dart pub global activate melos 3.4.0
ENV PATH="$PATH":"$HOME/.pub-cache/bin"
ENV FLUTTER_HOME "/home/mobiledevops/.flutter-sdk"
ENV PATH $PATH:$FLUTTER_HOME/bin

# get growerp repos
#RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git /opt/growerp
#RUN cp /opt/growerp/flutter /home/mobiledevops/growerp
# copy from local below, two lines above from repository
COPY --chown=mobiledevops:mobiledevops . /home/mobiledevops/growerp
WORKDIR /home/mobiledevops/growerp
RUN melos exec flutter clean
RUN melos clean
RUN melos bootstrap
RUN melos build --no-select && melos l10n --no-select; 
RUN melos exec flutter pub get
VOLUME /home/mobiledevops/growerp/test


