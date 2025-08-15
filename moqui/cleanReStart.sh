#! /bin/bash
./gradlew cleandb
java -jar moqui.war load types=seed,seed-initial,install no-run-es
java -jar moqui.war no-run-es

