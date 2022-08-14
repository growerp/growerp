
# Technical Introduction.

GrowERP Admin Flutter frontend component for Android, IOS and Web using https://flutter.dev This application is build for the stable version of flutter, you can find the installation instructions at: https://flutter.dev/docs/get-started

Although all screens work on IOS/Anderoid/Web devices however a smaller screen will show less information but it is still usable.

It is a simplified frontend however with the ability to still use with, or in addition to the original ERP system screens.
The system is a true multicompany system and can support virtually any ERP backend as long as it has a REST interface.

The system is implemented with https://pub.dev/packages/flutter_bloc state management with the https://bloclibrary.dev documentation, data models, automated integration tests and a separated rest interface for the different backend systems. 

The system configuration file is in /assets/cfg/app_settings.json. Select OFBiz or Moqui here.

For test purposes we can provide access to Moqui or OFBiz systems in the cloud.

Additional ERP systems can be added on request, A REST interface is required.
The implementation time is 40+ hours.

# To run the system locally.
After installation of [Java 11](https://openjdk.java.net/install/):
  
Moqui backend: (preferred)
  https://github.com/growerp/growerp-moqui/README.md

OR...Apache OFBiz backend:
  https://github.com/growerp/growerp-ofbiz/blob/master/README.adoc

clone and run the WebSocket chat server(optional)
  https://github.com/growerp/growerp-chat  

Flutter app, after [installation of Flutter](https://flutter.dev/docs/get-started/install):
```
git clone https://github.com/growerp/growerp
$ cd growerp/packages/core
$ flutter pub run build_runner build
$ ../admin
$ flutter run
```
create your first company!
