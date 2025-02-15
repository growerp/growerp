# Environemnt to install flutter and build web
FROM debian:latest AS build-env

# install all needed stuff
RUN apt-get update
RUN apt-get install -y curl git unzip

RUN useradd -ms /bin/bash myuser
USER myuser
ENV HOME=/home/myuser

# define variables
ARG FLUTTER_SDK=$HOME/flutter
ARG FLUTTER_VERSION=3.27.0

#clone flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
# change dir to current flutter folder and make a checkout to the specific version
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION

# setup the flutter path as an enviromental variable
ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:${PATH}"

# Start to run Flutter commands
# doctor to see if all was installes ok
RUN flutter doctor -v

# activate melos
RUN dart pub global activate melos 3.4.0
ENV PATH="$PATH":"$HOME/.pub-cache/bin"

# copy source code to folder
WORKDIR $HOME
RUN git clone --depth 1 https://github.com/growerp/growerp
WORKDIR $HOME/growerp/flutter
# COPY --chown=myuser:myuser . $HOME # copy from local
RUN sed -i 's\//webactivate \\' $HOME/growerp/flutter/packages/admin/lib/main.dart
RUN melos clean
RUN melos bootstrap
# localization
RUN melos l10n --no-select
# build
RUN melos build --no-select
# build flutter app
# Run build: 1 - clean, 2 - pub get, 3 - build web
WORKDIR $HOME/growerp/flutter/packages/admin
RUN flutter clean
RUN flutter pub get
RUN flutter build web

# once here the app will be compiled and ready to deploy

# use nginx to deploy
FROM nginx:1.25.2-alpine

# copy the info of the build web app to nginx
COPY --from=build-env /home/myuser/growerp/flutter/packages/admin/build/web /usr/share/nginx/html

# Expose and run nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
