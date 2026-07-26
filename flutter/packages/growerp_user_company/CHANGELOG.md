## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers); lengthen pubspec description.

## 1.11.0

 - **REFACTOR**: Remove localization dependency from CompanyUserBloc and update messages. ([f4883b6f](https://github.com/growerp/growerp/commit/f4883b6fe45c2bc86ff60cf01f0270037f00b917))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**(flutter): support optional full-screen rendering for UserDialog and CompanyDialog. ([7de30fdd](https://github.com/growerp/growerp/commit/7de30fddeeff689f96efdb1624151057c11d1f6e))
 - **REFACTOR**: convert user and company routes to modal dialogs using DialogPage and update navigation logic to support overlay push. ([23768fe1](https://github.com/growerp/growerp/commit/23768fe15ed82bd222de449020fad30c6aa5678b))
 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **FIX**: update visibility keys and improve layout in user dialog and popup components for integration test. ([c1edbbf8](https://github.com/growerp/growerp/commit/c1edbbf8947e7874746a80d15c5814f4e10c04af))
 - **FIX**(tests): repair desktop-layout integration test keys. ([bf44ed59](https://github.com/growerp/growerp/commit/bf44ed593baf7ac674514845f6027d4a6171f06d))
 - **FIX**(tests): repair long-standing desktop/mobile integration test failures. ([3ad7b9f8](https://github.com/growerp/growerp/commit/3ad7b9f88361d94c6b9147a05fe1a27f825c36ba))
 - **FIX**: UserDialog no-id without create signal shows current user again. ([7f6c6c5f](https://github.com/growerp/growerp/commit/7f6c6c5ff7c5af392355638a11a83ee35b9fbd0f))
 - **FIX**: chat create opens a real, prefilled new-record form (Phase 2). ([a477a3ff](https://github.com/growerp/growerp/commit/a477a3ffcfc3727fa2d6f5d7bd543c5a9125e3f8))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: admin Company tab blank — metadata builder defaulted to _NEW_. ([992b1fbc](https://github.com/growerp/growerp/commit/992b1fbc0202f5ddd95439e82a4046ab69d32b6d))
 - **FIX**: user test. ([d72985dc](https://github.com/growerp/growerp/commit/d72985dc5a664bf75f9651e74df154ff0ad2952c))
 - **FIX**: prevent infinite rebuild loop in display menu options by memoizing injected configurations and disable builtInKotlin in Android gradle properties. ([96ec2454](https://github.com/growerp/growerp/commit/96ec2454ff151c7298d880e6be59fc5a22a2a1d1))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: more test corrections. ([0706aada](https://github.com/growerp/growerp/commit/0706aadac60106447fd1016615932bf10af571f7))
 - **FIX**: product test. ([a8a0fc85](https://github.com/growerp/growerp/commit/a8a0fc8524a74fef91904348422ca61fdb576778))
 - **FIX**: automated tests. ([770bb01b](https://github.com/growerp/growerp/commit/770bb01bde8cb950ed897bf09a6b04f14c61d6e5))
 - **FIX**: user cutomer test. ([82a0d815](https://github.com/growerp/growerp/commit/82a0d815abbdf4214ee74f5925050c0f2d44a28f))
 - **FIX**: apache.commons.fileupload upgrade in moqui4: fix upload and implement image deletion support for companies, users, and products with backend service integration and UI synchronization. ([e9609dc5](https://github.com/growerp/growerp/commit/e9609dc5d8357e2a77c930018aa90320f49fbd1c))
 - **FIX**: fixing general problems running tests on other than mobile devices, created general used demo message screen, catalog swag demo now run on Linux, should run on win and mac too. ([289a163c](https://github.com/growerp/growerp/commit/289a163cd38a92230f1660e5d0e69ca15b357638))
 - **FIX**: core test and statistics phone dashboard. ([655d2c82](https://github.com/growerp/growerp/commit/655d2c82a081a38e9a02c476dfe57626f634ef14))
 - **FIX**: show growerp logo at login screen. ([87ae8a42](https://github.com/growerp/growerp/commit/87ae8a42e24215d7f860a29aa75df2c4d7916262))
 - **FIX**: app bar company not show dialog. ([077c33d0](https://github.com/growerp/growerp/commit/077c33d081a58a3178424b26e9a1c20101902788))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: company image not showing. ([8b7a78b8](https://github.com/growerp/growerp/commit/8b7a78b899bd4f4a312c40d875e758b9edd65398))
 - **FIX**: package user_company intergration tests passed. ([3419f830](https://github.com/growerp/growerp/commit/3419f8304eb2897d0b1060c4edec54847b378750))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: various test errors. ([132af2ba](https://github.com/growerp/growerp/commit/132af2ba5e2a0ccbb6b7a8c8d5756c620b7efaa7))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: core integration tests. ([f794d236](https://github.com/growerp/growerp/commit/f794d2361403ef907f0069622de7fee2d66414dc))
 - **FIX**: enhance state management in dialogs and blocs; improve loading behavior and error handling: result of automated tests. ([746c9f1c](https://github.com/growerp/growerp/commit/746c9f1c605c0cf6119c7661de1d5c97108ae245))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: centralize image picking logic into `HelperFunctions` and enhance web loading screen UI with a circular logo container. ([a04a579a](https://github.com/growerp/growerp/commit/a04a579a2d5e6fd1b2f904907aa61fb77930f462))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**(tests): repair desktop-layout integration test failures. ([f72ae43c](https://github.com/growerp/growerp/commit/f72ae43ce6a315f9c3c5574c51f2d8fb9c78755e))
 - **FIX**: update employee causes duplicate postal record. ([804c1858](https://github.com/growerp/growerp/commit/804c185827e246f500d5eff5d33d67fbf3af811a))
 - **FIX**: upgraded and fixed the chat function. ([1909eb76](https://github.com/growerp/growerp/commit/1909eb7673ebb3964ebf410d5df5aa17ad31de02))
 - **FIX**: various errors in screens. ([b8f0f973](https://github.com/growerp/growerp/commit/b8f0f973e3c9d416eb82f3525751dac4844c8145))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: corrected login for employees, chat working again. ([a2cd64f9](https://github.com/growerp/growerp/commit/a2cd64f905c94139a3831891660d9a2fadfd32ea))
 - **FIX**: owner list REST access, company email/phone and broken view. ([057cfeb7](https://github.com/growerp/growerp/commit/057cfeb704742572a1f744279aabba86f8e083d5))
 - **FIX**: build error & cleanup. ([0ed97436](https://github.com/growerp/growerp/commit/0ed974361b2524e9302993b60cf43bcad86aa947))
 - **FIX**: improve reliability of test record retrieval by using search instead of row indexing now running the tests separately for mobile and desktop. ([7782eb6d](https://github.com/growerp/growerp/commit/7782eb6dbf6376cac1de5b4d83d7477d71603850))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: dynamic menu test. ([9158d362](https://github.com/growerp/growerp/commit/9158d3629c39e77c88641be7b9efa1880b3620ad))
 - **FIX**: reorganized companyuser tests. ([e62c46c0](https://github.com/growerp/growerp/commit/e62c46c0056b40821d239a6bee8b8cc4e1de93b2))
 - **FIX**: position of floating buttons on larger than phone screens. ([183a3437](https://github.com/growerp/growerp/commit/183a3437a1af689a5aeebaaafa2e5dbed03ffc1d))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: outreach order-accounting website automated tests. ([1f1b70f8](https://github.com/growerp/growerp/commit/1f1b70f8f80ed0b4de71eb74d3fe00912aa1bc36))
 - **FIX**: integrated tests: user_company, sales. ([f22cd5a0](https://github.com/growerp/growerp/commit/f22cd5a04f79ac48e9b60cd784ece24040853d0d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: all build and lint errors..TODO remained.... ([331ca65a](https://github.com/growerp/growerp/commit/331ca65aa3b66fe18c3853718be610404b55b641))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([5f16c849](https://github.com/growerp/growerp/commit/5f16c84918f5f2db0e500097a962446fddb7ae87))
 - **FIX**: revenue report and various floating buttons positions. ([e3bb2069](https://github.com/growerp/growerp/commit/e3bb2069e3998ef4581a9372401e89fbbf33d905))
 - **FIX**: add employee to main company. ([1d4904ce](https://github.com/growerp/growerp/commit/1d4904ce8f9e97049847df8b1a3e92042ba83839))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: company_user_customer_test. ([5a7ad2c4](https://github.com/growerp/growerp/commit/5a7ad2c4feeb8a446c8a1cfacc51cb9c5056749a))
 - **FIX**: customer user test. ([ebeaf465](https://github.com/growerp/growerp/commit/ebeaf465256ed16a3c04de836e377819a882fe62))
 - **FIX**: customer company integration test. ([8d7aef36](https://github.com/growerp/growerp/commit/8d7aef36c22e5e4008cdf952446ed63ee3261b81))
 - **FIX**: update printing dependency version across multiple packages. ([b30da509](https://github.com/growerp/growerp/commit/b30da509c125bdd7f2b59233a42cecc6f22a6a75))
 - **FIX**: corrected IOS and MacOS problems reported by the appstore. ([895e64c0](https://github.com/growerp/growerp/commit/895e64c051f046547629ed2c54862cb52de12fa7))
 - **FIX**: update key for OutlinedButton in UserDialog to improve widget identification. ([0e2fff68](https://github.com/growerp/growerp/commit/0e2fff68dec1cacc9470641dfde038be0c2f0a1c))
 - **FIX**: various corrections on previous merge from Jules. ([dfcc02a8](https://github.com/growerp/growerp/commit/dfcc02a8869a0290c9cc0415d4d0d1f1d49d138a))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**(tests): robust desktop reopen + tab label for user_company. ([7784e381](https://github.com/growerp/growerp/commit/7784e3815aac147a46c0ce8fa963fb53c29b8dfe))
 - **FIX**: lead tests. ([ec992d86](https://github.com/growerp/growerp/commit/ec992d8626480b9e4f41ce387f3ea4ea8dee95e2))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: user dialog delete button/upload/list, upgraded printing for firestore studio. ([a6eec3dc](https://github.com/growerp/growerp/commit/a6eec3dcd700c345b3929a5af420d7343aaf1c76))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: user/company tests after adding localizations. ([8ebff37a](https://github.com/growerp/growerp/commit/8ebff37ae61361c04592c1803aba5613a464b27c))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: various thai translations. ([cbcbe480](https://github.com/growerp/growerp/commit/cbcbe480516a9dba71e39c3cea7586ea178080c6))
 - **FIX**: improve scrolling user list. ([9cb4a92b](https://github.com/growerp/growerp/commit/9cb4a92bc3543f03a2efb35f523c7e77808a09c7))
 - **FIX**: revert part of POC html site, removed loading ind. ([1b911396](https://github.com/growerp/growerp/commit/1b911396ef5249eb072e25ad433f54aee0ed7570))
 - **FIX**: various changes in the company, user, companyUser lists and dialog. ([4e814151](https://github.com/growerp/growerp/commit/4e814151b92c1e007261751f6183702ce49af73c))
 - **FIX**: accept empty price in product upload, remove print, add test to vsconfig. ([1f3206fd](https://github.com/growerp/growerp/commit/1f3206fde2537b72417797fe8d0c1898bbc22f79))
 - **FIX**: remove duplicate hero keys. ([866c4243](https://github.com/growerp/growerp/commit/866c4243fe5513b7983f319233abb939a645f947))
 - **FIX**: only show floating update button on mobile. ([6674c925](https://github.com/growerp/growerp/commit/6674c925dcc090027e407b8f8caf6beb1ea28b66))
 - **FIX**: camera and image upload on company dialog. ([be1334ee](https://github.com/growerp/growerp/commit/be1334ee9b9e5f5d0f61ed4225a666bd10f4e495))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([93216258](https://github.com/growerp/growerp/commit/932162588cac34b8689ab5eeb8fecb1a2d38153a))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: VERY first version of subscriptions. ([2ca41795](https://github.com/growerp/growerp/commit/2ca41795b4de9181cded554d91a30bcc8779edc9))
 - **FEAT**: added a credit card capture for a trial period, updated tests. ([f6b2123b](https://github.com/growerp/growerp/commit/f6b2123b672407300bb3207a3955f64c16310473))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**(l10n): Translate growerp_user_company to Thai. ([d3b0e4c4](https://github.com/growerp/growerp/commit/d3b0e4c4d83729964c83196a699c585b711e662e))
 - **FEAT**: add update/add floating button to user dialogs. ([66363ce1](https://github.com/growerp/growerp/commit/66363ce14aa81ffc6bd911bd2daff971e18bf8ef))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**(l10n): Add Thai translation for growerp_user_company. ([486ff486](https://github.com/growerp/growerp/commit/486ff486bce51d16cb1ee97e461cd91385de0afc))
 - **FEAT**: user-company translations. ([b54e9419](https://github.com/growerp/growerp/commit/b54e9419f2843875a318e7ea35325680d88ead17))
 - **FEAT**: activity translations. ([4c0806e2](https://github.com/growerp/growerp/commit/4c0806e230693a81d7a94f594056a99ce066ebed))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: make url/email clickable in user list. ([5b689e12](https://github.com/growerp/growerp/commit/5b689e12b2d0f13de9d5ac3ff8001048ef3bc0cb))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([cc48d8fe](https://github.com/growerp/growerp/commit/cc48d8fe4144b55c23f6f3633537d612e595e286))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: first version of the assesment package. ([c57ae654](https://github.com/growerp/growerp/commit/c57ae6541cb41dcedb1e15a0eb780a55b31137cd))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: added an AIprompt button on all windows, AI apikey can be set at accounting/systemSetup. ([90ecb38f](https://github.com/growerp/growerp/commit/90ecb38fbc85a77ca4012afbb8d6f26bec260f9e))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**: Add `/user` route to display user profile as a standalone page and update authentication state upon user profile changes. ([1eaeea40](https://github.com/growerp/growerp/commit/1eaeea4003558c2fa8718466e738bf403ff680b5))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: add unit of measure and amount to the product definition, restructuring and fixing product test. ([c2623bf4](https://github.com/growerp/growerp/commit/c2623bf416e98f34a166397bf5234801ba1dda6f))
 - **FEAT**: enhance user registration to support multi-tenant creation and trial flows with dedicated services and UI. ([605d1f47](https://github.com/growerp/growerp/commit/605d1f476cc11f5469487d1de8baeff48748e4b5))
 - **FEAT**: Introduce styled data table components and common UI widgets for standardized list and detail views for the core and companyuser components, integration tests success. ([ed18d7f5](https://github.com/growerp/growerp/commit/ed18d7f5efb5221867210e95c4906ba2b4041bbe))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: dynamically load all currencies from the backend and upgrade currency selection fields to use autocomplete. ([10752274](https://github.com/growerp/growerp/commit/10752274141937636720599be06fc670695adf3b))
 - **FEAT**: add "Owners" menu item to support and register the `CompanyListMainOnly` widget. ([2e201d85](https://github.com/growerp/growerp/commit/2e201d8589e34b87f3150eb6a5f4ac3d1a1fc9a9))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**: show owner REST stats on support owner record, removed RESTAPI listing". ([c3257693](https://github.com/growerp/growerp/commit/c3257693151a29871854a41c0600f09316679ba6))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: prefill create/edit dialogs from chat directive params (Phase 2). ([55b34e90](https://github.com/growerp/growerp/commit/55b34e907a2d25b906674174d1b23382ef76d69d))
 - **FEAT**(outreach): async LinkedIn lead import with job title + completion notification. ([00761e7e](https://github.com/growerp/growerp/commit/00761e7e0f8f486bbe422315ba00261981fb0795))
 - **FEAT**: Application UI graphical enhancements. ([2bb2c074](https://github.com/growerp/growerp/commit/2bb2c07489532dbef086017d899815875cb37b0f))

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
