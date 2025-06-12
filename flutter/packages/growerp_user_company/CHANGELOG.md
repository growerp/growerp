## 1.9.0

 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: lead tests. ([a9657cbb](https://github.com/growerp/growerp/commit/a9657cbb8889ac0bf592761c962db70c96311ad6))
 - **FIX**: add employee to main company. ([fe69163c](https://github.com/growerp/growerp/commit/fe69163c761cc077b0d0a57130ab8126a4171649))
 - **FIX**: revenue report and various floating buttons positions. ([e1b3229a](https://github.com/growerp/growerp/commit/e1b3229adfc4346537c2ed36235f9b6bc7f7607c))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([aff11499](https://github.com/growerp/growerp/commit/aff11499cfe4997b4a0daf991aed057e919a64d9))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([bf58df13](https://github.com/growerp/growerp/commit/bf58df13e5bf8e32d8001a9554ab45c9d6080951))
 - **FIX**: position of floating buttons on larger than phone screens. ([12382c49](https://github.com/growerp/growerp/commit/12382c499b1f9c42097e055c63058f2959b165ce))
 - **FIX**: reorganized companyuser tests. ([a9f9a805](https://github.com/growerp/growerp/commit/a9f9a8054027db637a05c7782a8de305f67044a3))
 - **FIX**: build error & cleanup. ([9241caf9](https://github.com/growerp/growerp/commit/9241caf9595474b786451f879fce1929a13c2584))
 - **FIX**: corrected login for employees, chat working again. ([87f41e77](https://github.com/growerp/growerp/commit/87f41e7797ca0a2af5b03305c6b0cc4e004f8598))
 - **FIX**: upgraded and fixed the chat function. ([fbe6e2a4](https://github.com/growerp/growerp/commit/fbe6e2a43b2cbf890714e33cf2cb8aa24b0046c9))
 - **FIX**: update employee causes duplicate postal record. ([a19856da](https://github.com/growerp/growerp/commit/a19856dad7167c849737414f16496b19e8de3dd0))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: company image not showing. ([68b4b9b9](https://github.com/growerp/growerp/commit/68b4b9b91ffd09b189ffee239482f67ba5fef084))
 - **FIX**: show growerp logo at login screen. ([88149c19](https://github.com/growerp/growerp/commit/88149c192c108584fae84889cf62cdff576860d4))
 - **FIX**: user cutomer test. ([14ac5dbd](https://github.com/growerp/growerp/commit/14ac5dbdfe0a53157a5a6ebe8eb7a0f750ffbc8f))
 - **FIX**: automated tests. ([3a37dee7](https://github.com/growerp/growerp/commit/3a37dee74327b0fb9f5265f424cecd92fedf7ac4))
 - **FIX**: product test. ([4007efb9](https://github.com/growerp/growerp/commit/4007efb9ef3c618dcf42ef552742b87674d594ef))
 - **FIX**: more test corrections. ([0532d380](https://github.com/growerp/growerp/commit/0532d38024697eeb3d7c127ccf71f08dc26896b1))
 - **FIX**: user test. ([e411b568](https://github.com/growerp/growerp/commit/e411b56820c81d07d7bdb0b9c3a5c1d72fe2117f))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([36d8a9ea](https://github.com/growerp/growerp/commit/36d8a9eae858751911af57f955cd66d670633d3d))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* various changes

## 1.3.0
* various changes

## 1.2.1
* upgrade to growerp_core 1.2.3

## 1.2.0
* upgrade to growerp_core 1.2.0
* upgrade to growerp_core 1.2.0
* models in separate package
* Now using retrofit

## 1.1.3
* upgrade to growerp_core 1.1.3

## 1.1.0
*  moved bloc to the core package
*  user list improved
*  searchdropdown upgraded 

## 1.0.0
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors
* added localization
* upgrade dart 3

## 0.9.2
* upgrade of core package

## 0.9.0
* Company and User bloc/view now separated
* User/company tests extracted from core
* User/Company related api calls moved from core
* only dependant on growerp_core

## 0.9.0-dev.1
* Initial extracted from growerp_core.
