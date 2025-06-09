This is the Task/Event part of the GrowERP system.

It contains the following file maintenance screens:

- Event
- ToDo

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        "databaseUrlDebug": https://backend.growerp.org
        "chatUrlDebug": "wss://chat.growerp.org"

Start test with melos: (activate with: dart global activate melos) 
```sh
melos build_all
melos l10n
cd example
flutter test integration_test
```
## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the Core component you have to create a company which sends an email with a password. Use this password to login and the Core components appear in the main menu.

