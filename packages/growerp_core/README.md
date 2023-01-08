This is the core package of the GrowERP frontend.

It is called from an Flutter application like the app in the example directory.

It provides the core of the system:
- Initialize the REST interface
- Access security
- Multi company access
- Company creation and maintance
- User maintenace
- Task maintenance.

a full admin system is available in the 'admin' app. 

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        databaseUrlDebug: https://test.growerp.org
Start test with: cd example && flutter test integration_test/all_test.dart

## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the Core component you have to create a company which sends an email with a password. Use this password to login and the Core components appear in the main menu.

