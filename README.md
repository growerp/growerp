# Welcome to flutter open source GrowERP.

GrowERP is an open source multi platform ERP application you can try right now!

We have now started a production version:
- Web:     https://admin.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.admin
- IOS:     https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755

The next version with limited availability you can try at:
- Web:     https://admin.growerp.org

When the application is started, create a new company, select demo data or an empty system and look around!

If you like this initiative, please give a star to the project.
 
Documentation available at https://www.growerp.com

We also created a first vertical app for Hotel owners which will be released later. 
- Web:     https://hotel.growerp.org
- Android: https://play.google.com/store/apps/details?id=org.growerp.hotel
- IOS:     https://apps.apple.com/us/app/growerp-admin-open-source/id1531267095

The next version with limited availability you can try at:
- Web:     https://hotel.growerp.org

## Use GrowERP locally

You just need this repository at https://github.com/growerp/growerp
The next version is in the development branch

### start the chat server
```sh
cd chat
./gradlew/apprun
```

### start backend in separate terminal
Initialize:
```sh
    cd moqui
    ./gradlew downloadel #only first time
    ./gradlew cleanall
    ./gradlew build
    java -jar moqui.war load types=seed,seed-initial,install
```
Run:
```sh
    cd moqui
    java -jar moqui.war
```
### build flutter system:

Install 'melos' and build: 
```sh
dart pub global install melos
cd growerp
melos bootstrap
melos build_all
melos l10n
```

### emulator/browser
start emulator or use browser and start app in directory: packages/admin:
```sh
cd flutter/packages/admin
flutter run
```
## Use with docker

In the docker directory there is a README.md to run the complete system in docker images locally.

### Some phone screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-dashboard.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-account.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-catalog.png" width="200">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-ledgers.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-orders.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/phoneScreenshots/Pixel_4_API_31-website.png" width="200">
            </td>
        </tr>
    </table>
</div>

### Some web/tablet screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/teninchScreenshots/Nexus_10_API_30-dashboard.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/teninchScreenshots/Nexus_10_API_30-account.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/teninchScreenshots/Nexus_10_API_30-catalog.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/teninchScreenshots/Nexus_10_API_30-ledgers.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/images/teninchScreenshots/Nexus_10_API_30-website.png" width="600">
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
