#!/bin/bash
#
# Copyright (c) 2023-2024 GrowERP. All rights reserved.
#
# ALL RIGHTS ARE RESERVED FOR THE AUTHORS OF THIS FILE.
# This file is being made available under the Digital Asset License 1.0 (DAL).
# The DAL is available at https://www.growerp.com/DAL-1.0
#
# This file may be used by anyone who has purchased a license for the GrowERP system.
# The license must be valid and current.
#
# See the LICENSE file in the root of this repository for details.
#
export DEBIAN_FRONTEND=noninteractive
# Install Dart SDK (using apt, official Google repo)
sudo apt-get update
sudo apt-get install -y apt-transport-https wget
# new method for adding keys
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/dart.gpg >/dev/null
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install -y dart
# Add Dart to PATH
export PATH="$PATH:/usr/lib/dart/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"

cd flutter || exit
dart pub global activate melos
melos clean
melos bootstrap
melos l10n --no-select
melos build --no-select
