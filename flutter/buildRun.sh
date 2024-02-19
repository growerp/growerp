#! /bin/bash
set -x
docker compose -f docker-compose.test.yml down
docker image rm flutter-sut:latest
docker image rm flutter-moqui:latest
docker compose -f docker-compose.test.yml up

