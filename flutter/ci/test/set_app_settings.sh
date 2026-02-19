#! /bin/bash
# DEPRECATED: This script is no longer used.
# Test configurations are now baked into the Docker image during build
# to prevent modification of source files.
# See Dockerfile for the sed commands that configure app_settings.json
set -x
if [ -f "assets/cfg/app_settings.json" ]; then
    sed -i -e 's|"databaseUrlDebug": "[^"]*"|"databaseUrlDebug": "http://moqui"|g' assets/cfg/app_settings.json
    sed -i -e 's|"chatUrlDebug": "[^"]*"|"chatUrlDebug": "ws://moqui"|g' assets/cfg/app_settings.json
fi

if [ -f "example/assets/cfg/app_settings.json" ]; then
    sed -i -e 's|"databaseUrlDebug": "[^"]*"|"databaseUrlDebug": "http://moqui"|g' example/assets/cfg/app_settings.json
    sed -i -e 's|"chatUrlDebug": "[^"]*"|"chatUrlDebug": "ws://moqui"|g' example/assets/cfg/app_settings.json
fi
