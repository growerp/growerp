#! /bin/bash
#
# Rebuild and test frontend and backend
# search for [E] in the result for errors.
#
set -x
clear
docker compose -f docker-compose.test.yml down
docker image rm flutter-sut:latest -f
docker image rm flutter-moqui:latest -f
docker system prune -f
# docker volume prune -af
cd /tmp
rm -rf /tmp/growerp
cp ~/growerp /tmp -r && cd growerp
#if [ -d growerp ]; then
#  cd growerp && git pull
#else
#  git clone git@github.com:growerp/growerp.git && cd growerp
#fi
cd flutter
docker compose -f docker-compose-test.yml up

