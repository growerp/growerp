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
echo "y" | docker system prune
docker compose -f docker-compose.test.yml up

