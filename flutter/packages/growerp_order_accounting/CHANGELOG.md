## 1.9.0

 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **FIX**: build error & cleanup. ([9241caf9](https://github.com/growerp/growerp/commit/9241caf9595474b786451f879fce1929a13c2584))
 - **FIX**: revenue report and various floating buttons positions. ([e1b3229a](https://github.com/growerp/growerp/commit/e1b3229adfc4346537c2ed36235f9b6bc7f7607c))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([aff11499](https://github.com/growerp/growerp/commit/aff11499cfe4997b4a0daf991aed057e919a64d9))
 - **FIX**: revenue/expense report. ([7e9316fb](https://github.com/growerp/growerp/commit/7e9316fb6bf0c941286b561a1384c4fcbc2ac79c))
 - **FIX**: room rental and opporunity test. ([5562a7a3](https://github.com/growerp/growerp/commit/5562a7a322bbf31409a21343758613fa4aef630e))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([bf58df13](https://github.com/growerp/growerp/commit/bf58df13e5bf8e32d8001a9554ab45c9d6080951))
 - **FIX**: position of floating buttons on larger than phone screens. ([12382c49](https://github.com/growerp/growerp/commit/12382c499b1f9c42097e055c63058f2959b165ce))
 - **FIX**: reorganized companyuser tests. ([a9f9a805](https://github.com/growerp/growerp/commit/a9f9a8054027db637a05c7782a8de305f67044a3))
 - **FIX**: request test. ([1b37a5ba](https://github.com/growerp/growerp/commit/1b37a5badff2cf64135ba79954b2cbdba9bfa20b))
 - **FIX**: order rental test. ([6cde28cb](https://github.com/growerp/growerp/commit/6cde28cb93e58460390f778b1d02e7917580731b))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FIX**: glaccount up/download. ([fc790df7](https://github.com/growerp/growerp/commit/fc790df7971f233b232def1e707948777b4c1940))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: adjust gateway response for phone sized screen. ([f9045c3e](https://github.com/growerp/growerp/commit/f9045c3ed76b254def6285918ed38acbaa7df849))
 - **FIX**: show placed/approve date instead of creation date when available. ([ba3d3111](https://github.com/growerp/growerp/commit/ba3d31117d26800ebfdd1252d24a14d770e62e5c))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: payment purchase test. ([19c6ce2e](https://github.com/growerp/growerp/commit/19c6ce2eefcd77fc447ab6e3e42962746ddfeab2))
 - **FIX**: conversion changes: close and update period totals by year. ([09b66538](https://github.com/growerp/growerp/commit/09b66538f856457105d4b00dadf1c2018cd6f765))
 - **FIX**: change conversion quantities and lint error. ([654d0b6d](https://github.com/growerp/growerp/commit/654d0b6df67d1ccc265153873516da5f61364a64))
 - **FIX**: dart lint and log warnings. ([41eec765](https://github.com/growerp/growerp/commit/41eec765eb5da60a4a0362bbc2be9c649a691bd7))
 - **FIX**: conversion split closing of documents in parts. ([f78f1a10](https://github.com/growerp/growerp/commit/f78f1a102c5853b184fc5d8b1657e419ee401793))
 - **FIX**: when only zero values on revenue/expense reports show a message instead of zero values. ([ec31b697](https://github.com/growerp/growerp/commit/ec31b6974a77dc00d6eee83d39c4f53ce3cff010))
 - **FIX**: moqui update Dockerfile, add email birdsend parameters. ([9511304b](https://github.com/growerp/growerp/commit/9511304bb8fd9f2afb74ee6910e2cbc9a323470b))
 - **FIX**: health app telephone. ([c4a77134](https://github.com/growerp/growerp/commit/c4a7713488b94370aa0f95168c16414d183a2c28))
 - **FIX**: remove confusion of having the same data records in 2 files. ([9b6d1817](https://github.com/growerp/growerp/commit/9b6d1817240c3fb0a373ef79ebc9e91db950d756))
 - **FIX**: update reservation dialog with header and field decoration. ([9976735a](https://github.com/growerp/growerp/commit/9976735a81772d0de57e13b3ab983d14c68ea67f))
 - **FIX**: conversion import correction, with userinterface adjustments in inventory/assets/locations. ([702348dc](https://github.com/growerp/growerp/commit/702348dca0cdbc92054143961059e65e4cfa94a6))
 - **FIX**: conversion & UI enhancements. ([a83a41cc](https://github.com/growerp/growerp/commit/a83a41cc9abfe02fb1394c06bcccb5ea39d1cd1e))
 - **FIX**: purchase payment test. ([f239c7f9](https://github.com/growerp/growerp/commit/f239c7f9d9d01b6a2c161c774960a831f5794884))
 - **FIX**: purchase invoice test. ([10999b1a](https://github.com/growerp/growerp/commit/10999b1a047c85d68eb8eab2251775e8e7b118b8))
 - **FIX**: automated integration test for ledger transactions. ([81ef5b62](https://github.com/growerp/growerp/commit/81ef5b6268fa814af41361d6fe95a2a983bc5ae5))
 - **FIX**: automated integrations tests, last fixes? ([b7222c65](https://github.com/growerp/growerp/commit/b7222c656f0826146a44e104d4014fae47d18311))
 - **FIX**: more test corrections. ([0532d380](https://github.com/growerp/growerp/commit/0532d38024697eeb3d7c127ccf71f08dc26896b1))
 - **FIX**: more integrated test corrections. ([68c1ae8a](https://github.com/growerp/growerp/commit/68c1ae8ae3e5e5ad5fe318064f808e029e4b4ac7))
 - **FIX**: integration tests. ([31f9a430](https://github.com/growerp/growerp/commit/31f9a4308c8c2f70e89aa7b3ff15f71119cf6485))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: occupancy check in order rental. ([8a24ee94](https://github.com/growerp/growerp/commit/8a24ee949de9bb1aa422283bd24c976c67d04895))
 - **FIX**: health request form adjustments. ([b3f1a82b](https://github.com/growerp/growerp/commit/b3f1a82b80a9f030311e3e7599922d79e64fac58))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([36d8a9ea](https://github.com/growerp/growerp/commit/36d8a9eae858751911af57f955cd66d670633d3d))
 - **FEAT**: added the revenue/expense line chart. ([dfba6a09](https://github.com/growerp/growerp/commit/dfba6a09d066600e5e853a8c31a5a3d8e42c5dbf))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* package upgrade

## 1.3.0
* various changes

## 1.2.1
* upgrade to growerp_core 1.2.3

## 1.2.0
* upgrade to growerp_core 1.2.0
* models in separate package
* Now using retrofit
* Any ledger organization and numbering possible by upload or manual entry.
* Manual ledger transactions and posting added.
* Ledger journal function added
* Relation of order/invoice/payment/shipment documents now shown and clickable.
* Added trial balance

## 1.1.3
* upgrade to growerp_core 1.1.3

## 1.1.0
* upgraded searchdropdown
* rental screens changed for hotel app

## 1.0.1
* freezed files missing

## 1.0.0
* added localization
* updated to dart 3
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors 
* add accounting reports
* show date at order/invoice
* company now at order/invoice level
 
## 0.9.2
* Merged invoice itemType and paymentItemType
* adapted payment tests
* only show itemtypes when a glAccount is assigned
* added header to receive shipment dialog

## 0.9.0
* Upgrade to core 0.9.0.

## 0.9.0-dev.1
* Refactoring and UI improvements.

## 0.8.0-dev.1nn
* Initial version.

