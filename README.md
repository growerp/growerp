# Welcome to flutter open source GrowERP.

GrowERP is an open source multi platform ERP application you can use right now!

We have now started a production admin version:
- Web:     https://admin.growerp.com
- Android: https://play.google.com/store/apps/details?id=org.growerp.admin
- IOS:     https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755

We also created a vertical app for Hotel owners: 
- Web:     https://hotel.growerp.org
- Android: https://play.google.com/store/apps/details?id=org.growerp.hotel
- IOS:     https://apps.apple.com/app/growerp-hotel-open-source/id1531267095 

When the application is started, create a new company, select demo data or an empty system and look around!

Documentation available at https://www.growerp.com

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
    ./gradlew downloadel #only one time
    ./gradlew cleanall   #only one time
    ./gradlew build      #only one time
    java -jar moqui.war load types=seed,seed-initial,install
```
Run:
```sh
    cd moqui
    java -jar moqui.war
```
### run the flutter system:

### run the flutter emulator or browser
```sh
cd flutter/packages/admin
flutter run
```
## Use with docker
Super simple! 
In the docker directory there is a README.md to run the complete system with docker images locally.

## Some phone screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420540.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420567.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420650.png" width="200">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420590.png" width="200">
            </td>            
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420597.png" width="200">
            </td>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_1690420644.png" width="200">
            </td>
        </tr>
    </table>
</div>

### Some web/tablet screen shots:
<div style="text-align: center">
    <table>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422126.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422138.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422142.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422148.png" width="600">
            </td>            
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422152.png" width="600">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422156.png" width="600">
            </td>
        </tr>
        <tr>
            <td style="text-align: center">
                    <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_1690422191.png" width="600">
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
