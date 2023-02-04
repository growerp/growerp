This 'website' plugin for the GrowERP flutter frontend system
provide ways to configure the website created for you.  

Features:
    1. Change the domainname the website will be shown under.
    2. Change the main title of the website.
    3. Enter google statistics id for awesome visititor statistics.  
    4. Show text pages with images emtered in markdown format.
    5. Define the product categories which will be shown.
    6. define the products which will be shown in the 'featured' or 'deals' section on the home page.
    7. Be able to upload an obsidian/logseq vault
 
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

