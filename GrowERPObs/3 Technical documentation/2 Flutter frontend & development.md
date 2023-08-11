## How to start development with flutter

## Software you need.
The following software is required to customise and run the system:
 1. Java SDK 11 (Ubuntu: sudo apt install openjdk-11-jdk)
 2. Flutter with emulators (Ubuntu: sudo snap install flutter --classic)
 3. IDE: VsCode or Android IDE

## Moqui back-end
The Moqui back-end has a build-in database which need to be initialized with the database model stored inside Moqui and has to be loaded with initial data. Together with compiling the moqui framework created a complete system.

The moqui backend should run in a separate terminal which is initialized with the following commands:
```bash
cd moqui
./gradlew downloadElasticsearch
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install
```

And to start it with:
```bash
java -jar moqui.war
```
## Chat server.

Also the chat server should run in a separate terminal and can be started with the following command:
```sh
./gradlew apprun
```

## Start the flutter frontend
Now you can start the flutter fontend with:

```sh
cd packages/admin
flutter run
```
or for Hotel:
```sh
cd packages/hotel
flutter run
```
## Using local packages
In the above case the packages from pub.dev are being used. If you like to customize the system you have to activate the locally stored packages by the following command after you have activated the 'melos' command with: 'dart pub global activate melos'

This command will create package override files which will activate the local stored packages.

However this is not enough, the local packages also use 'Freeze' to generate the 'copyWith' commands and the data model back-end interface fromJson and ToJson functions. To generate these, again use the melos program with the command 'melos build_all'

The last generation what is required is to generate the language localization files with again the Melos package with the command: 'melos l10n'

Now you have a system which is using the local package sources and you are able to change them. The last command will start the flutter without rebuilding

To summarise the building process:
```bash
cd growerp/flutter
melos bootstrap
melos build_all
melos l10n
```
