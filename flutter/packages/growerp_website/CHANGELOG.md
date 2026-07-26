## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers); lengthen pubspec description.

## 1.11.0

 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: implement versioned CSS cache busting and update Lumina theme color derivation logic. ([a62bab62](https://github.com/growerp/growerp/commit/a62bab624c14cdeaa1cc0f46a5f80389aa123e9a))
 - **REFACTOR**: created html website templates, streamline store pricing UI, add module navigation, and update service definitions, overhaul store footer UI components with modern design and update deployment script references. ([0d7851f8](https://github.com/growerp/growerp/commit/0d7851f81a962fe7d8d14a4e4d725558a341cbca))
 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **FIX**: outreach order-accounting website automated tests. ([1f1b70f8](https://github.com/growerp/growerp/commit/1f1b70f8f80ed0b4de71eb74d3fe00912aa1bc36))
 - **FIX**: Prevent `Autocomplete` disposal issues by removing conditional `LoadingIndicator` for product and category data. ([ffaaaa00](https://github.com/growerp/growerp/commit/ffaaaa006e341a01efdb79de9f0e8058884e232e))
 - **FIX**: various test errors. ([132af2ba](https://github.com/growerp/growerp/commit/132af2ba5e2a0ccbb6b7a8c8d5756c620b7efaa7))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: update application ID to com.example.example across example Android build configurations. ([dbf96c32](https://github.com/growerp/growerp/commit/dbf96c32f3d3b60c5ba007ad9d8a9ff8dca89365))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: integrated tests: user_company, sales. ([f22cd5a0](https://github.com/growerp/growerp/commit/f22cd5a04f79ac48e9b60cd784ece24040853d0d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: all build and lint errors..TODO remained.... ([331ca65a](https://github.com/growerp/growerp/commit/331ca65aa3b66fe18c3853718be610404b55b641))
 - **FIX**: fixes to assesment and landing page, landingpage/checkoutOnePage/admin paths now viewable in website dialog, demo data for landingpage. ([f1ea9f73](https://github.com/growerp/growerp/commit/f1ea9f7395c48f41c61c4414f492724f2b77196c))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: website and purchase payment test. ([041e317b](https://github.com/growerp/growerp/commit/041e317bdda28487e66db59781802a680083531e))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: build error & cleanup. ([0ed97436](https://github.com/growerp/growerp/commit/0ed974361b2524e9302993b60cf43bcad86aa947))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: show growerp logo at login screen. ([87ae8a42](https://github.com/growerp/growerp/commit/87ae8a42e24215d7f860a29aa75df2c4d7916262))
 - **FIX**: website test. ([abc49206](https://github.com/growerp/growerp/commit/abc49206a57b269af6da929e36ae268461df5242))
 - **FIX**: now just have a single website per owner. ([7cecfe8d](https://github.com/growerp/growerp/commit/7cecfe8d43e682a44dc154fbf92bb65686cdeca5))
 - **FIX**: dark/light mode in content edit. ([1699c1b7](https://github.com/growerp/growerp/commit/1699c1b7ce9aedfa8926b3d7b1f117d9c41771ef))
 - **FIX**: integration tests. ([16d23365](https://github.com/growerp/growerp/commit/16d233658c786b44de8607c1edb875b4cc03a1e4))
 - **FIX**: user test. ([d72985dc](https://github.com/growerp/growerp/commit/d72985dc5a664bf75f9651e74df154ff0ad2952c))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FEAT**: improve design of list/detail screens of catalog, order/accounting and inventory. ([ebb9bb56](https://github.com/growerp/growerp/commit/ebb9bb5637ff25a4c8a68cbcfb9f2a49879ee3da))
 - **FEAT**: modernize benefits page with new Bento-style UI and integrate into GrowERP website seed data. ([f46dbc86](https://github.com/growerp/growerp/commit/f46dbc86bc702ecd538232b92887a3445767b38a))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: Merge remote-tracking branch 'origin/feat/website-localization with website translations'. ([7db8709a](https://github.com/growerp/growerp/commit/7db8709a9103d79d07eca85f1c3a666e4c950b76))
 - **FEAT**: implement website theme color picker and integration tests for modern templates. ([eed6b7b7](https://github.com/growerp/growerp/commit/eed6b7b7e27b3db413ae1b2278c7e1d5f2a2a17d))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**: allow direct zip file uploads for Obsidian and add dynamic header/footer styling to the website. ([251edde1](https://github.com/growerp/growerp/commit/251edde1b1c70b0a004f42b96633de785ef1405f))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: use your own payment processor. ([05b4abdd](https://github.com/growerp/growerp/commit/05b4abdd8e7bba453009da81ef67cb6e6ddd7979))
 - **FEAT**: move some fiekds aeround and fix update public content update logic. ([cbbca619](https://github.com/growerp/growerp/commit/cbbca619568ae548a4649f0c28d2d34a82e8c560))
 - **FEAT**: prepare for automation on substack and linkedin. ([4bc12197](https://github.com/growerp/growerp/commit/4bc1219774e459ab3c0fbc5a710cbbfbc04d70da))
 - **FEAT**(website): per-page SEO metadata + lead-capture form builder. ([be69deec](https://github.com/growerp/growerp/commit/be69deecec284c90d60d2f37f1d7bf7c56a3a87f))
 - **FEAT**: implement selectable modern tailwind templates for websites. ([165888ff](https://github.com/growerp/growerp/commit/165888ff0ea578a3bad7d0b3909d4274af69804e))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: Enhance XML Schema and website follow us Definitions. ([9539c19b](https://github.com/growerp/growerp/commit/9539c19b7d8e718b758aebcff2c375789f7581ea))
 - **FEAT**(marketing): unify landing pages with website forms into one tenant-scoped system. ([d0df630d](https://github.com/growerp/growerp/commit/d0df630d9a39c6762597a7556328292058de5107))
 - **FEAT**: Implement HTTP response caching with `dio_cache_interceptor`, configurable cache duration, and cache invalidation on logout and mutating requests. ([adece8f9](https://github.com/growerp/growerp/commit/adece8f919faa3be095382c02ddc2c5621a5f5e7))
 - **FEAT**: add comprehensive URL change tests in WebsiteTest class. ([b217d6b6](https://github.com/growerp/growerp/commit/b217d6b61bf86e711df1c7db002a74333b41d36e))
 - **FEAT**(website): Localize user-facing strings. ([d3b78f7f](https://github.com/growerp/growerp/commit/d3b78f7fd56d5bc3c395b18bde22baf2e1d8cbe7))

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
