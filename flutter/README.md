# GrowERp Flutter directory.

This directory contains all files related to the Flutter frontend applications.

Applications are stored as packages in the packages directory. Most packages have an 'example' application to be able to try the package and run the integration tests in the integration_test directory.

## hierarchy of packeges

Packages are dependent of each other, bottom up:
    1. growerp_models
    2. growerp_chat
        1. growerp_core
        2. growerp
            1. growerp_catalog
            2. growerp_order_acounting
            3. growerp_inventory
            4. growerp_website
            5. growerp_marketing
            6. growerp_user_company
                1. admin
                2. hotel
                3. freelance


## Integration test,
A docker compose and Dockerfile are provided in this directory to be able to run integration tests either in the background or in the cloud. It contains an android emulator used in the tests. This emulator is configured the way the Android studio emulator is configured with the same screen size.
To be able to run the tests in the background, the adb ports are at 5556/5557 so they are not conflicting with a possible Android studio emulator.

For the background processes also a Moqui, database and chat server are started. The internet gateway service is used to validate chat requests with the moqui backend.

To start the background test:
```bash
cd growerp/flutter
./buildRun.sh
```

See futher the README.md file in the root of this project.

## integration test restart
If you once ran the integration test and like to run again you have to delete the emulator container (docker container rm emulator) before restarting

if you want to rebuild the flutter frontend and backe-end and/or chat you have to delete the containers and related images:
```bash
docker container -f rm container-name
docker image rm image-name
```
## For developers: build the system

```sh
dart pub global activate melos # only one time
melos clean
melos bootstrap # remove references to pub.dev and use local packages
melos build     # generate data models
melos l10n      # generate language localization files
```
