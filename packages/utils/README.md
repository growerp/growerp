# GrowERP utils

package with utilities to manage the GrowERP system

the following directory structure is assumed which can be created by
the create_dev_rel_environment.dart utility

growerp -> flutterDevelopment github.com/growerp/growerp branch: development
        -> flutterRelease     github.com/growerp/growerp branch: master
        -> moquiDevelopment   github.com/growerp/.... growerp-moqui branch: development
        -> moquiRelease       github.com/growerp/.... growerp-moqui branch: master
        -> chatDevelopment    github.com/growerp/growerp-chat branch: development
        -> chatRelease        github.com/growerp/growerp-chat branch: master


## create_dev_rel_environment.dart
Create your release/development environment.
You might want to create your own development branch from the development branch and create pull requests to the development branch. The master branch will not be changed directly but only by merging from another branch, either development or another emergency fix branch.

1. Will create the above directory structure from 'home'
2. get files from github.
3. will run all build methods and fill db with minimal data.
4. will start chat and moqui backend
5. will start flutter using the currently available platform

## switch_prod_dev.dart
switch pubspec.yaml files between test( all packages local via path) to using the packages from pub.dev and the reverse. Used when releasing a new version.

## screenshots
will create screenshots using the (old driver) integration tests for all the emulators which are defined.

1. cd packages/admin
2. flutter pub run utils:screenshots

## runIntegration

will install the front/backend system and run all integration tests from the admin package

1. clone https://githhub.com/growerp/growerp
2. cd growerp/packages/admin
3. flutter pub run utils:runIntegration

## run all growerp_* package tests: growerp system in ~/growerp directory
1. packages/utils/bin/all_test.dart




