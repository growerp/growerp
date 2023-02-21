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

#Stage 1 - Install dependencies and build the app
FROM debian:latest AS build-env

# Install flutter dependencies
RUN apt-get update && \
    apt-get install -y curl git wget zip unzip libgconf-2-4 gdb libstdc++6 \
        libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 nano && \
    apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter && \
    /usr/local/flutter/bin/flutter doctor -v

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# set flutter channel
RUN flutter channel stable && flutter upgrade

# Copy files to container and build
RUN git clone https://github.com/growerp/growerp.git /usr/local/growerp
WORKDIR /usr/local/growerp/packages/admin
RUN /usr/local/flutter/bin/flutter build web --release

# Stage 2 - Create the run-time image
FROM nginx
COPY --from=build-env /usr/local/growerp/packages/admin/build/web /usr/share/nginx/html
EXPOSE 80
