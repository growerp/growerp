# Welcome to Flutter open source GrowERP.

GrowERP is an open source multi platform ERP application you can use right now!

<span style="color:red">
Currently using flutter latest stable version
</span>.

## PRODUCTION version:
Admin application
- Web:     https://admin.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.admin
- IOS:     https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755

Hotel application: 
- Web:     https://hotel.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.hotel
- IOS:     https://apps.apple.com/app/growerp-hotel-open-source/id1531267095 

## TEST NEXT version:
Admin application
- Web:     https://admin.growerp.org

Hotel application: 
- Web:     https://hotel.growerp.org

When the application is started, create a new company, select demo data or an empty system, login and use the password sent by email and look around! Provide comments to support@growerp.com

Documentation available at https://www.growerp.com

# Install GrowERP locally

## What is needed? 
    Java JDK 11:    https://www.oracle.com/th/java/technologies/javase/jdk11-archive-downloads.html
    Java JDK 17:    Flutter now need gradle V8 up, which needs Java v17
                    Make java 11 the default and tell flutter to use 17 with: flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64  
    Flutter:        https://flutter.dev/  currently 3.29.2
    Chrome:         https://www.google.com/chrome/  
    Git:            https://git-scm.com/downloads  
    Android studio: https://developer.android.com/studio  
    VS code:        https://code.visualstudio.com/  

## To install GrowERP the easy way:

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

### start backend in separate terminal
Initialize: (only the first time)
```sh
cd moqui
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install no-run-es
```
Run:
```sh
cd moqui
java -jar moqui.war no-run-es
```
### run the flutter emulator or browser
Initialize; (only the first time)
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
```
Run:
```sh
flutter run
```
for hotel go to the flutter/packages/hotel directory and submit 'flutter run' command
login to the backend: 
    http://localhost:8080/vapps user: SystemSupport password: moqui

## Use GrowERP locally with docker
In the docker directory there is a README.md to run the complete system with docker images locally.

## Some phone screen shots from the admin App:
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

### Some web/tablet admin screen shots:
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
## Some phone screen shots from the *hotel* App:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-day.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-week-menu.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/rooms.png" width="200">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/reservations.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/accounting.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/ledger.png" width="200">
            </td>
        </tr>
    </table>
</div>

### Some web/tablet *Hotel* screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-day.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-week.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/rooms.png" width="600">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/reservations.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/accounting.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/ledger.png" width="600">
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
