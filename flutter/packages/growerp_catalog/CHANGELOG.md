## 1.9.0

 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: product and category upload from screen. ([95e02996](https://github.com/growerp/growerp/commit/95e029961577f6a86eff19a246c041c0b1d7b6df))
 - **FIX**: lead tests. ([a9657cbb](https://github.com/growerp/growerp/commit/a9657cbb8889ac0bf592761c962db70c96311ad6))
 - **FIX**: category test. ([bf79027c](https://github.com/growerp/growerp/commit/bf79027c39c441202d06c4dcc45c6c1902bdeee5))
 - **FIX**: align category and asset list to the standard UI. ([2213eeb9](https://github.com/growerp/growerp/commit/2213eeb949c59b6d24d603d53fbc7ddcc6519f15))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([aff11499](https://github.com/growerp/growerp/commit/aff11499cfe4997b4a0daf991aed057e919a64d9))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([bf58df13](https://github.com/growerp/growerp/commit/bf58df13e5bf8e32d8001a9554ab45c9d6080951))
 - **FIX**: position of floating buttons on larger than phone screens. ([12382c49](https://github.com/growerp/growerp/commit/12382c499b1f9c42097e055c63058f2959b165ce))
 - **FIX**: build error & cleanup. ([9241caf9](https://github.com/growerp/growerp/commit/9241caf9595474b786451f879fce1929a13c2584))
 - **FIX**: upgraded and fixed the chat function. ([fbe6e2a4](https://github.com/growerp/growerp/commit/fbe6e2a43b2cbf890714e33cf2cb8aa24b0046c9))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: ui improvements and dart generall fixes. ([cac1e074](https://github.com/growerp/growerp/commit/cac1e074d41e4881543d0c180d33af63831adbbb))
 - **FIX**: product test. ([4007efb9](https://github.com/growerp/growerp/commit/4007efb9ef3c618dcf42ef552742b87674d594ef))
 - **FIX**: category test. ([58feb67c](https://github.com/growerp/growerp/commit/58feb67c3b555617c74acaab21ff5411cfd6b756))
 - **FIX**: integration tests. ([31f9a430](https://github.com/growerp/growerp/commit/31f9a4308c8c2f70e89aa7b3ff15f71119cf6485))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FIX**: marketing and catalog test. ([c9398234](https://github.com/growerp/growerp/commit/c939823452125d04855d5a9cd1699f9aa4db3082))
 - **FIX**: update reservation dialog with header and field decoration. ([9976735a](https://github.com/growerp/growerp/commit/9976735a81772d0de57e13b3ab983d14c68ea67f))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* model changes

## 1.3.0
* various changes

## 1.2.1
* upgrade to growerp_core 1.2.3

## 1.2.0
* upgrade to growerp_core 1.2.0
* models in separate package
* Now using retrofit
* added import/export

## 1.1.3
* upgrade to growerp_core 1.1.3

## 1.1.0
* upgraded search drop down
* moved product/asset/catagory into the core
* fixed headers of various forms 

## 1.0.0
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors
* added localization
* upgrade dart 3
* floating buttons only show when at the top
* refactor product dialog 

## 0.9.2
* upgrade of core package

## 0.9.0

* upgrade of core package

## 0.9.0-dev.1

* Refactoring and UI improvements.

## 0.8.0-dev.1

* Upgrade the growerp_core package.

## 0.7.0-dev.2

* use update growerp_core.

# 0.7.0-dev.1

* initial dev release.
