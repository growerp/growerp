## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers).

## 1.11.0

 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: update subscription dialog to dynamically fetch and display product plans from DataFetchBloc. ([fd01461e](https://github.com/growerp/growerp/commit/fd01461e3d2ff0d4247c2fe3f8b765636816f165))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **FIX**: centralize image picking logic into `HelperFunctions` and enhance web loading screen UI with a circular logo container. ([a04a579a](https://github.com/growerp/growerp/commit/a04a579a2d5e6fd1b2f904907aa61fb77930f462))
 - **FIX**(tests): repair desktop-layout integration test keys. ([bf44ed59](https://github.com/growerp/growerp/commit/bf44ed593baf7ac674514845f6027d4a6171f06d))
 - **FIX**: chat create opens a real, prefilled new-record form (Phase 2). ([a477a3ff](https://github.com/growerp/growerp/commit/a477a3ffcfc3727fa2d6f5d7bd543c5a9125e3f8))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: improve integration test reliability, asset test/glaccount test. ([99cda03b](https://github.com/growerp/growerp/commit/99cda03b7a6397854b21fb422c9444e3d1c6146f))
 - **FIX**: integration tests. ([16d23365](https://github.com/growerp/growerp/commit/16d233658c786b44de8607c1edb875b4cc03a1e4))
 - **FIX**: category test. ([c802bead](https://github.com/growerp/growerp/commit/c802bead95f14091f2e703024eff4e36cef2b626))
 - **FIX**: wrap grouping decorator content in Material widget and add generated macOS ephemeral configuration files. ([5dcdb5e8](https://github.com/growerp/growerp/commit/5dcdb5e89376e8e25d151188bfb6c0e7b6e141d3))
 - **FIX**: product test. ([a8a0fc85](https://github.com/growerp/growerp/commit/a8a0fc8524a74fef91904348422ca61fdb576778))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: ui improvements and dart generall fixes. ([5551f7a3](https://github.com/growerp/growerp/commit/5551f7a36fd88d061edf0960746e7fa07f644534))
 - **FIX**: update video player plugin reference. ([b5b551e2](https://github.com/growerp/growerp/commit/b5b551e2028d366a692da3246f11a685c84929b3))
 - **FIX**: integrate trial welcome flow, refine onboarding prompt logic, and update automated integration tests. ([e292b66b](https://github.com/growerp/growerp/commit/e292b66b1fbf0e44f0ac72ed133ed5f671f889c8))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**: marketing and catalog test. ([ee24fb55](https://github.com/growerp/growerp/commit/ee24fb55b0c6464f8dfe144a9e2d498387b6b2ab))
 - **FIX**: upgraded and fixed the chat function. ([1909eb76](https://github.com/growerp/growerp/commit/1909eb7673ebb3964ebf410d5df5aa17ad31de02))
 - **FIX**: build error & cleanup. ([0ed97436](https://github.com/growerp/growerp/commit/0ed974361b2524e9302993b60cf43bcad86aa947))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: apache.commons.fileupload upgrade in moqui4: fix upload and implement image deletion support for companies, users, and products with backend service integration and UI synchronization. ([e9609dc5](https://github.com/growerp/growerp/commit/e9609dc5d8357e2a77c930018aa90320f49fbd1c))
 - **FIX**: manufacturing tests. ([5897e63c](https://github.com/growerp/growerp/commit/5897e63cd0c1bb33d3adaf709500d8854425939d))
 - **FIX**: cleaup sales package and added main option in catalog example. ([e1ed485c](https://github.com/growerp/growerp/commit/e1ed485ca4c65cc3284c357e4c39ed87586ef035))
 - **FIX**: fixing general problems running tests on other than mobile devices, created general used demo message screen, catalog swag demo now run on Linux, should run on win and mac too. ([289a163c](https://github.com/growerp/growerp/commit/289a163cd38a92230f1660e5d0e69ca15b357638))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: various test errors. ([132af2ba](https://github.com/growerp/growerp/commit/132af2ba5e2a0ccbb6b7a8c8d5756c620b7efaa7))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([93216258](https://github.com/growerp/growerp/commit/932162588cac34b8689ab5eeb8fecb1a2d38153a))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**: enhance state management in dialogs and blocs; improve loading behavior and error handling: result of automated tests. ([746c9f1c](https://github.com/growerp/growerp/commit/746c9f1c605c0cf6119c7661de1d5c97108ae245))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([5f16c849](https://github.com/growerp/growerp/commit/5f16c84918f5f2db0e500097a962446fddb7ae87))
 - **FIX**: align category and asset list to the standard UI. ([6efdd0b0](https://github.com/growerp/growerp/commit/6efdd0b06fd281cbaaa16bfe3a236ac176b1065e))
 - **FIX**: category test. ([93f90014](https://github.com/growerp/growerp/commit/93f90014fcb0a2206003e1a433a7542e06f31bb8))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: lead tests. ([ec992d86](https://github.com/growerp/growerp/commit/ec992d8626480b9e4f41ce387f3ea4ea8dee95e2))
 - **FIX**: product and category upload from screen. ([b881eeb4](https://github.com/growerp/growerp/commit/b881eeb4acfeb02dc01188ba0cf654dbaff73d86))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: improve integration test stability with `pumpAndSettle` and update navigation calls to use new route paths. ([aef9da76](https://github.com/growerp/growerp/commit/aef9da76474de36028269569b67001c27da56201))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: accept empty price in product upload, remove print, add test to vsconfig. ([1f3206fd](https://github.com/growerp/growerp/commit/1f3206fde2537b72417797fe8d0c1898bbc22f79))
 - **FIX**: subscription test & debugged function. ([eec77aba](https://github.com/growerp/growerp/commit/eec77abaf1f5102dfb078d1a1a334e625b3ea746))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FIX**: corrected IOS and MacOS problems reported by the appstore. ([895e64c0](https://github.com/growerp/growerp/commit/895e64c051f046547629ed2c54862cb52de12fa7))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: basic tests of order_accounting, activity. ([7dfc0ffc](https://github.com/growerp/growerp/commit/7dfc0ffccea352ba09f1b30f000ce8c52825c12d))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: update reservation dialog with header and field decoration. ([690db5d0](https://github.com/growerp/growerp/commit/690db5d0ead673df8b6495b4a508489fc3030762))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: catalog integration tests. ([f4deb53f](https://github.com/growerp/growerp/commit/f4deb53f9a68e6f0d287f320b78e1baea6e0d38f))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: belong to last commit. ([8d46bc16](https://github.com/growerp/growerp/commit/8d46bc16c94b89177d2302cc5e6933245fdd4a05))
 - **FIX**: when thai language selected show the buddist year. ([6e998fb4](https://github.com/growerp/growerp/commit/6e998fb4c44377a62ad17d3aaff3cc7bd69e75b5))
 - **FIX**: position of floating buttons on larger than phone screens. ([183a3437](https://github.com/growerp/growerp/commit/183a3437a1af689a5aeebaaafa2e5dbed03ffc1d))
 - **FEAT**: VERY first version of subscriptions. ([2ca41795](https://github.com/growerp/growerp/commit/2ca41795b4de9181cded554d91a30bcc8779edc9))
 - **FEAT**: Merge remote-tracking branch 'origin/catalog_translate with corrections'. ([588e6485](https://github.com/growerp/growerp/commit/588e64855945ae52828e89383851c0ad73491a24))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: add unit of measure and amount to the product definition, restructuring and fixing product test. ([c2623bf4](https://github.com/growerp/growerp/commit/c2623bf416e98f34a166397bf5234801ba1dda6f))
 - **FEAT**: extend the subscriptions and show current growerp plan in accounting setup. ([cb99d898](https://github.com/growerp/growerp/commit/cb99d898a43245f3204a37496e3a64d37924842e))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: Application UI graphical enhancements. ([2bb2c074](https://github.com/growerp/growerp/commit/2bb2c07489532dbef086017d899815875cb37b0f))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: enhance user registration to support multi-tenant creation and trial flows with dedicated services and UI. ([605d1f47](https://github.com/growerp/growerp/commit/605d1f476cc11f5469487d1de8baeff48748e4b5))
 - **FEAT**: improve design of list/detail screens of catalog, order/accounting and inventory. ([ebb9bb56](https://github.com/growerp/growerp/commit/ebb9bb5637ff25a4c8a68cbcfb9f2a49879ee3da))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: replace DropdownSearch with AutocompleteLabel for subscriber and product selection. ([eec0b714](https://github.com/growerp/growerp/commit/eec0b7141cf0737c7d67cbdbbfa3b8b74da3c3d6))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: Extended main menu for Tasks and Freelance dashboard. ([531c9836](https://github.com/growerp/growerp/commit/531c983698823673b7f6b29c5674255b5cdf5b3b))
 - **FEAT**: dynamically load all currencies from the backend and upgrade currency selection fields to use autocomplete. ([10752274](https://github.com/growerp/growerp/commit/10752274141937636720599be06fc670695adf3b))
 - **FEAT**: Implement HTTP response caching with `dio_cache_interceptor`, configurable cache duration, and cache invalidation on logout and mutating requests. ([adece8f9](https://github.com/growerp/growerp/commit/adece8f919faa3be095382c02ddc2c5621a5f5e7))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: deeplink for IOS ,add entitlements and apple-app-site-association for admin and hotel applications. ([e5e9c4ae](https://github.com/growerp/growerp/commit/e5e9c4ae7b4558d084457fbd58bb24283df595f1))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**: implement local session persistence for API keys and tokens while refining auth error handling. ([2b09618d](https://github.com/growerp/growerp/commit/2b09618d85f8e82232801d5d7b9187f120000dec))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**: implement GL account code masking, improve WebSocket connection handling, and refine notification bloc logic. ([284bc3e9](https://github.com/growerp/growerp/commit/284bc3e9f2234dd0ccc38842f6ebf016610511ac))
 - **FEAT**: implement ADK agent job management and migrate agent config model to shared package. ([7834eebd](https://github.com/growerp/growerp/commit/7834eebdd351dade6929124802edc6f7554b34b0))
 - **FEAT**: implement modular LLM provider configuration and migrate existing Gemini API keys. ([53c1256a](https://github.com/growerp/growerp/commit/53c1256a8e54ec9a0ec64dc8cfd1af065587e2de))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: prefill create/edit dialogs from chat directive params (Phase 2). ([55b34e90](https://github.com/growerp/growerp/commit/55b34e907a2d25b906674174d1b23382ef76d69d))
 - **FEAT**: implement LLM system usage tracking, add monthly token limit settings, and expose audit logs via a new dashboard view. ([901e8197](https://github.com/growerp/growerp/commit/901e8197f898b9dc60e6bdfbbb902b3c018b4c30))
 - **FEAT**: implement website theme color picker and integration tests for modern templates. ([eed6b7b7](https://github.com/growerp/growerp/commit/eed6b7b7e27b3db413ae1b2278c7e1d5f2a2a17d))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **DOCS**: actualize app and building-block README files. ([1d0c980a](https://github.com/growerp/growerp/commit/1d0c980a326734bffc3afbe6e000bb38505d2ef9))

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
