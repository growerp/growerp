#!/bin/bash
# Install Dart SDK (using apt, official Google repo)
sudo apt-get update
sudo apt-get install -y apt-transport-https wget
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install -y dart
# Add Dart to PATH
export PATH="$PATH:/usr/lib/dart/bin"
cd flutter
dart pub global activate melos
melos clean
melos bootstrap
melos l10n --no-select
melos build --no-select
