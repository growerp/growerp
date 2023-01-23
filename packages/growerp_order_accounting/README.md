# An Order and Accounting plugin for the GrowERP system.

Please see the https:/www.growerp.com for documentation.

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        databaseUrlDebug: https://test.growerp.org
Start test with: cd example && flutter test integration_test/opportunity_test.dart

## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the CRM component you have to create a company which sends an email with a password. Us this password to login and the CRM component appear in the main menu. Select CRM and the following screen will appear.
