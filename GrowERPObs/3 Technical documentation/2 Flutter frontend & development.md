## How to start development with flutter
## Moqui back-end

The Moqui back-end has a build-in database which need to be initialized with the database model stored inside Moqui and has to be loaded with initial data. Together with compiling the moqui framework created a complete system.

The moqui backend should run in a separate terminal which is initialized with the following commands:
```bash
cd moqui
./gradlew cleanAll
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
