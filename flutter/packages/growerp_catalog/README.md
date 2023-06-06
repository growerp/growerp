This is the Catalog part of the GrowERP system.

It contains the following file maintenance screens:

- Product
- Category
- Assets

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        databaseUrlDebug: https://test.growerp.org
Start test with: cd example && flutter test integration_test/all_test.dart

## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the Core component you have to create a company which sends an email with a password. Use this password to login and the components appear in the main menu.

