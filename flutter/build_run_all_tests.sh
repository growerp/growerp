#! /bin/bash
#
# Rebuild and test frontend and backend
# search for [E] in the result for errors.
#
set -x
clear
docker compose -f docker-compose.test.yml down
docker image rm flutter-sut:latest
docker image rm flutter-moqui:latest
docker system prune -f
# docker volume prune -af
if [ -d /tmp/growerp ]; then
  cd /tmp/growerp && git pull
else
  git clone git@github.com:growerp/growerp.git /tmp/growerp
fi
docker compose -f /tmp/growerp/flutter/docker-compose.test.yml up

