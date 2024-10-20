# Welcome to flutter open source GrowERP.

GrowERP is an open source multi platform ERP application you can use right now!

### PRODUCTION version:
Admin application
- Web:     https://admin.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.admin
- IOS:     https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755

Hotel application: 
- Web:     https://hotel.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.hotel
- IOS:     https://apps.apple.com/app/growerp-hotel-open-source/id1531267095 

### TEST NEXT version:
Admin application
- Web:     https://admin.growerp.org

Hotel application: 
- Web:     https://hotel.growerp.org

When the application is started, create a new company, select demo data or an empty system, login and use the password sent by email and look around! Provide comments to support@growerp.com

Documentation available at https://www.growerp.com

## Install GrowERP locally using global growerp command
## <span style="color:red">required flutter version channel stable</span> 

```sh
dart pub global activate growerp
growerp install
```

## Install GrowERP locally, manually
Get repository
```sh
git clone https://github.com/growerp/growerp
cd growerp
```

### start the chat server
```sh
cd chat
./gradlew/apprun
```

### start backend in separate terminal
Initialize:
```sh
    cd moqui
    ./gradlew build      #only one time
    java -jar moqui.war load types=seed,seed-initial,install no-run-es
```
Run:
```sh
    cd moqui
    java -jar moqui.war no-run-es
```
### run the flutter emulator or browser
```sh
cd flutter/packages/admin
dart pub global activate melos 3.4.0
export PATH="$PATH":"$HOME/.pub-cache/bin"
melos clean
melos bootstrap
# localization
melos l10n --no-select
# build
melos build --no-select
flutter run
```
## Use GrowERP locally with docker
In the docker directory there is a README.md to run the complete system with docker images locally.

## Some phone screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_main_menu.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_catalog_products.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_website.png" width="200">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_accounting.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_ledger.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_company.png" width="200">
            </td>
        </tr>
    </table>
</div>

### Some web/tablet screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_main_menu.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_company.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_website.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_orders.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_accounting.png" width="600">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_ledger.png" width="600">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_products.png" width="600">
            </td>
        </tr>
    </table>
</div>

### The generated business website:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/GrowERPObs/media/website.png" width="600">
            </td>            
        </tr>
    </table>
</div>
