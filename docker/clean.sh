#! /bin/bash

rm -Rf runtime/
rm -Rf db/
rm -Rf elasticsearch/data/nodes
rm -Rf elasticsearch/logs

docker rm moqui-server
docker rm moqui-database
docker rm nginx-proxy
