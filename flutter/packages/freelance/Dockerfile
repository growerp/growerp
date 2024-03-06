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
# with: docker build --build-arg DOCKER_TAG=1.3.0 -f packages/freelance/Dockerfile -t growerp/freelance . --progress=plain
#
#Stage 1 - Install dependencies and build the app
FROM growerp/flutter-sdk-image:3.16.9 AS build-env

ARG BRANCH=development # currently either master or development we need to add existing
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

# activate melos
RUN dart pub global activate melos
ENV PATH="$PATH":"$HOME/.pub-cache/bin"

# get growerp repos
USER mobiledevops
WORKDIR /home/mobiledevops
# RUN git clone --depth 1 -b $BRANCH https://github.com/growerp/growerp.git
COPY --chown=mobiledevops:mobiledevops . /home/mobiledevops/flutter
WORKDIR /home/mobiledevops/flutter
RUN echo "pwd: $PWD"
RUN flutter --version
RUN melos clean
RUN melos bootstrap
# localization
RUN melos l10n --no-select
# build
RUN melos build --no-select
# build flutter app
WORKDIR /home/mobiledevops/flutter/packages/freelance
RUN sed -i 's/version: .*/version: '"${DOCKER_TAG}"'/' pubspec.yaml
RUN flutter build web --release

# Stage 2 - Create the run-time image
FROM nginx
COPY --from=build-env /home/mobiledevops/flutter/packages/freelance/build/web /usr/share/nginx/html
EXPOSE 80
