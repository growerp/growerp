# GrowERP Sales (CRM/Opportunities) package

A CRM opportunity-pipeline plugin for the GrowERP system: track leads/prospects through a
sales pipeline.

It contains:

- Opportunity list and detail dialog
- Opportunity pipeline (Kanban board by stage, with a funnel summary)

Please see the https:/www.growerp.com for documentation.

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        databaseUrlDebug: https://test.growerp.org

Start test with: 
```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd example
flutter test integration_test/opportunity_test.dart
flutter test integration_test/pipeline_test.dart
```

## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the CRM component you have to create a company which sends an email with a password. Use this password to login and the CRM component appears in the main menu.
