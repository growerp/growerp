# GrowERp Flutter directory.

This directory contains all files related to the Flutter frontend applications.

Applications are stored as packages in the packages directory. Most packages have an 'example' application to be able to try the package and run the integration tests in the integration_test directory.


## Integration test,
A docker compose and Dockerfile are provided in this directory to be able to run integration tests either in the background or in the cloud. It contains an android emulator used in the tests. This emulator is configured the way the Android studio emulator is configured with the same screen size.
To be able to run the tests in the background, the adb ports are at 5556/5557 so they are not conflicting with a possible Android studio emulator.

For the background processes also a Moqui, database and chat server are started. The internet gateway service is used to validate chat requests with the moqui backend.

See the README.md file in the root of this project.

## For developers: build the system

```sh
dart pub global activate melos # only one time
melos clean
melos bootstrap # remove references to pub.dev and use local packages
melos build_all # generate data models
melos l10n      # generate language localization files
```
