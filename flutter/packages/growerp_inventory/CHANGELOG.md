## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers).

## 1.11.0

 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **FIX**: position of floating buttons on larger than phone screens. ([183a3437](https://github.com/growerp/growerp/commit/183a3437a1af689a5aeebaaafa2e5dbed03ffc1d))
 - **FIX**(inventory): avoid RangeError when asset row tapped during list refresh. ([f0c14b8d](https://github.com/growerp/growerp/commit/f0c14b8d483e180a175c4089a40d2338966961c1))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: improve integration test reliability, asset test/glaccount test. ([99cda03b](https://github.com/growerp/growerp/commit/99cda03b7a6397854b21fb422c9444e3d1c6146f))
 - **FIX**: asset dialog close race + search poll early-exit + endless pagination guard. ([43d9b715](https://github.com/growerp/growerp/commit/43d9b7156969016fb62b58bab473d9eac9d904ce))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: fixing general problems running tests on other than mobile devices, created general used demo message screen, catalog swag demo now run on Linux, should run on win and mac too. ([289a163c](https://github.com/growerp/growerp/commit/289a163cd38a92230f1660e5d0e69ca15b357638))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: inventory integration tests. ([42c3b904](https://github.com/growerp/growerp/commit/42c3b9046a6a8dccb3052f6a817e2aa681ce9350))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: various test errors. ([132af2ba](https://github.com/growerp/growerp/commit/132af2ba5e2a0ccbb6b7a8c8d5756c620b7efaa7))
 - **FIX**: enhance state management in dialogs and blocs; improve loading behavior and error handling: result of automated tests. ([746c9f1c](https://github.com/growerp/growerp/commit/746c9f1c605c0cf6119c7661de1d5c97108ae245))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: various errors in screens. ([b8f0f973](https://github.com/growerp/growerp/commit/b8f0f973e3c9d416eb82f3525751dac4844c8145))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: all build and lint errors..TODO remained.... ([331ca65a](https://github.com/growerp/growerp/commit/331ca65aa3b66fe18c3853718be610404b55b641))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: inventory integration tests. ([53641497](https://github.com/growerp/growerp/commit/536414972c2a768306a2614419191033bdec78c1))
 - **FIX**: update printing dependency version across multiple packages. ([b30da509](https://github.com/growerp/growerp/commit/b30da509c125bdd7f2b59233a42cecc6f22a6a75))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: additional changes belong to last commit. ([40ca0f42](https://github.com/growerp/growerp/commit/40ca0f429d0cdfb98d66f759b4e8b2545295555d))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: localization error is assets. ([0f50aa12](https://github.com/growerp/growerp/commit/0f50aa12e7fd70b419ffe60896d621c363f626c7))
 - **FIX**: translations inventory. ([fb345e4f](https://github.com/growerp/growerp/commit/fb345e4ff0ffeaf8ef59ef03fc5e7c0f1a55eee2))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FIX**: remove duplicate hero keys. ([866c4243](https://github.com/growerp/growerp/commit/866c4243fe5513b7983f319233abb939a645f947))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: align category and asset list to the standard UI. ([6efdd0b0](https://github.com/growerp/growerp/commit/6efdd0b06fd281cbaaa16bfe3a236ac176b1065e))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: show growerp logo at login screen. ([87ae8a42](https://github.com/growerp/growerp/commit/87ae8a42e24215d7f860a29aa75df2c4d7916262))
 - **FIX**: conversion import correction, with userinterface adjustments in inventory/assets/locations. ([e08d9f08](https://github.com/growerp/growerp/commit/e08d9f088bb1a71ef1a53d9af825980d6136b7fa))
 - **FIX**(tests): pin readyTarget element + layout-aware asset status label. ([890e26a7](https://github.com/growerp/growerp/commit/890e26a7a8107852bc4672d43a83e8283602effb))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([93216258](https://github.com/growerp/growerp/commit/932162588cac34b8689ab5eeb8fecb1a2d38153a))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**: build error & cleanup. ([0ed97436](https://github.com/growerp/growerp/commit/0ed974361b2524e9302993b60cf43bcad86aa947))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: various fixes and enhancements of the hotel app. ([5f666f52](https://github.com/growerp/growerp/commit/5f666f527b6dcfd8dbeca40abd91887728a06d32))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**: user dialog delete button/upload/list, upgraded printing for firestore studio. ([a6eec3dc](https://github.com/growerp/growerp/commit/a6eec3dcd700c345b3929a5af420d7343aaf1c76))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([5f16c849](https://github.com/growerp/growerp/commit/5f16c84918f5f2db0e500097a962446fddb7ae87))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**: Extended main menu for Tasks and Freelance dashboard. ([531c9836](https://github.com/growerp/growerp/commit/531c983698823673b7f6b29c5674255b5cdf5b3b))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: improve design of list/detail screens of catalog, order/accounting and inventory. ([ebb9bb56](https://github.com/growerp/growerp/commit/ebb9bb5637ff25a4c8a68cbcfb9f2a49879ee3da))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**(rental): rental vertical app with cars/equipment demo data. ([90425783](https://github.com/growerp/growerp/commit/9042578306b1de6dbd2c53655c4ea911bc204930))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **DOCS**: actualize app and building-block README files. ([1d0c980a](https://github.com/growerp/growerp/commit/1d0c980a326734bffc3afbe6e000bb38505d2ef9))

## 1.9.0

 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: align category and asset list to the standard UI. ([2213eeb9](https://github.com/growerp/growerp/commit/2213eeb949c59b6d24d603d53fbc7ddcc6519f15))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([aff11499](https://github.com/growerp/growerp/commit/aff11499cfe4997b4a0daf991aed057e919a64d9))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([bf58df13](https://github.com/growerp/growerp/commit/bf58df13e5bf8e32d8001a9554ab45c9d6080951))
 - **FIX**: position of floating buttons on larger than phone screens. ([12382c49](https://github.com/growerp/growerp/commit/12382c499b1f9c42097e055c63058f2959b165ce))
 - **FIX**: build error & cleanup. ([9241caf9](https://github.com/growerp/growerp/commit/9241caf9595474b786451f879fce1929a13c2584))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: conversion import correction, with userinterface adjustments in inventory/assets/locations. ([702348dc](https://github.com/growerp/growerp/commit/702348dca0cdbc92054143961059e65e4cfa94a6))
 - **FIX**: show growerp logo at login screen. ([88149c19](https://github.com/growerp/growerp/commit/88149c192c108584fae84889cf62cdff576860d4))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* package upgrade

## 1.3.0
* upgrade to growerp_core 1.2.3

## 1.2.1
* upgrade to growerp_core 1.2.3

## 1.2.0
* upgrade to growerp_core 1.2.0
* all models now in separate package
* switched to retrofit

## 1.1.3
* upgrade to growerp_core 1.1.3

## 1.1.0
* upgraded searchdropdown
* Moved blocs into the core

## 1.0.0
* added localization
* updated to dart 3
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors 
* added location test

## 0.9.0
* upgrade to new core package 0.9.0

## 0.9.0-dev.1
* Refactoring and UI improvements.

## 0.8.0-dev.1
- Upgrade core package

## 0.7.0-dev.1
- Initial version.
