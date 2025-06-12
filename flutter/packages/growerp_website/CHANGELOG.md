## 1.9.0

 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: build error & cleanup. ([9241caf9](https://github.com/growerp/growerp/commit/9241caf9595474b786451f879fce1929a13c2584))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: show growerp logo at login screen. ([88149c19](https://github.com/growerp/growerp/commit/88149c192c108584fae84889cf62cdff576860d4))
 - **FIX**: website test. ([ecb12a72](https://github.com/growerp/growerp/commit/ecb12a724a2accf101a71939e11595a99b50811f))
 - **FIX**: now just have a single website per owner. ([95eecbbe](https://github.com/growerp/growerp/commit/95eecbbe05317679deef8bfab4ad2a94104b1b68))
 - **FIX**: dark/light mode in content edit. ([d750d01e](https://github.com/growerp/growerp/commit/d750d01ee3ddc48091e02e79fbad990021e018da))
 - **FIX**: integration tests. ([31f9a430](https://github.com/growerp/growerp/commit/31f9a4308c8c2f70e89aa7b3ff15f71119cf6485))
 - **FIX**: user test. ([e411b568](https://github.com/growerp/growerp/commit/e411b56820c81d07d7bdb0b9c3a5c1d72fe2117f))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))
 - **FEAT**: use your own payment processor. ([6ad4e073](https://github.com/growerp/growerp/commit/6ad4e0732d29adf80cfcb6ccc6e7089afb703144))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* various upgrades

## 1.3.0
* upgrade to growerp_core 1.2.3

## 1.2.1
* upgrade to growerp_core 1.2.3

## 1.2.0
* upgrade to growerp_core 1.2.0
* models in separate package
* Now using retrofit

## 1.1.4
* fix error in growerp_select

## 1.1.3
* upgrade to growerp_core 1.1.3

## 1.1.0
* Upgraded with core package 1.1.0

## 1.0.0
* added localization
* updated to dart 3
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors## 0.9.2

## 0.9.0
* Upgrade to core 0.9.0

## 0.9.0-dev.1
* Refactoring and UI improvements.

## 0.8.0-dev.1
* Upgrade core package

## 0.6.0-dev.2
* Adapted to core package 0.7.0-dev.2
* Using now growerp_select_dialog:  ^0.6.0 because catalog taking out of core

## 0.6.0-dev.1
* initial dev release.
