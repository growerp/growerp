# to be build from the flutter directory
# with: docker build -f packages/admin/Dockerfile -t admin . --progress=plain
#

#Stage 1 - Install dependencies and build the app in a build environment
FROM debian:latest AS build-env

# Install flutter dependencies
RUN apt-get update
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 sed
RUN apt-get clean 

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="${PATH}:/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin"

# Run flutter doctor
RUN flutter doctor -v
RUN flutter channel stable
RUN flutter upgrade

# Copy files to container and build
RUN mkdir /app/
COPY . /app/
WORKDIR /app/

RUN echo "pwd: $PWD"
RUN flutter --version

# activate melos
RUN dart pub global activate melos
ENV PATH="$PATH":"/root/.pub-cache/bin"

# run melos
RUN melos clean
RUN melos bootstrap
# localization
RUN melos l10n --no-select
# build
RUN melos build --no-select
# build flutter app
WORKDIR /app/packages/admin
RUN sed -i 's/version: .*/version: '"${DOCKER_TAG}"'/' pubspec.yaml

RUN flutter build web --release

# Stage 2 - Create the run-time image
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/packages/admin/build/web /usr/share/nginx/html

