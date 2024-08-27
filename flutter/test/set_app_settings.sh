#! /bin/bash
set -x
sed -i -e 's\"databaseUrlDebug": "",\"databaseUrlDebug": "http://moqui",\g' assets/cfg/app_settings.json
sed -i -e 's\"chatUrlDebug": "",\"chatUrlDebug": "ws://chat:8080",\g' assets/cfg/app_settings.json
