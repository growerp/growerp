## 1.11.0

 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: fix various integration tets, improve testing robustness, update test data, and handle missing menu configurations gracefully. ([e3a9b3e9](https://github.com/growerp/growerp/commit/e3a9b3e915f31f122a513c04dc348b76c3dc5c9d))
 - **REFACTOR**: Replace DropdownSearch with Autocomplete in detail dialogs and refactor list displays with new styled data widgets for the order-accounting and catalog packages. ([0653340a](https://github.com/growerp/growerp/commit/0653340a354cf67d117830e3d8ea9799a1b73336))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**(ci): unmask summarize failures and fix the tests behind them. ([dcc464eb](https://github.com/growerp/growerp/commit/dcc464eb8aeb7fdc641d7459bd6af7fad48de6f1))
 - **FIX**(checkout): convert one-page USD payment to company currency. ([e217f630](https://github.com/growerp/growerp/commit/e217f6301496c6f7b8d3164974fd4d51978df845))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: improve integration test reliability, asset test/glaccount test. ([99cda03b](https://github.com/growerp/growerp/commit/99cda03b7a6397854b21fb422c9444e3d1c6146f))
 - **FIX**: key autocomplete option tiles so test taps by Key, not coordinates. ([5cd2ef54](https://github.com/growerp/growerp/commit/5cd2ef541f0c0b2332426e537eb36bceb285d99f))
 - **FIX**: GrowERP Order Purchase test. ([44358f1c](https://github.com/growerp/growerp/commit/44358f1cd87e41ba1b95b898c8cbc27ec48c711d))
 - **FIX**: gl_account test. ([781d81a6](https://github.com/growerp/growerp/commit/781d81a63566613c765c9c30ef286500b0387330))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: add platform check in updateWidget method for AccountingHomeWidget. ([033179e3](https://github.com/growerp/growerp/commit/033179e3782a77a3eda783172924faf19dbaac23))
 - **FIX**: hotel tests and faults. ([7b05f70e](https://github.com/growerp/growerp/commit/7b05f70e9bd3e0a946526c02f1e54bbbe75b5238))
 - **FIX**: various integration tests. ([55be7bdd](https://github.com/growerp/growerp/commit/55be7bddc150e30e100e9d2194ce21762ad56fd9))
 - **FIX**: humanize workeffort status. ([e9020b58](https://github.com/growerp/growerp/commit/e9020b58b04001532b6e2ae274beef35c761096a))
 - **FIX**: fixing general problems running tests on other than mobile devices, created general used demo message screen, catalog swag demo now run on Linux, should run on win and mac too. ([289a163c](https://github.com/growerp/growerp/commit/289a163cd38a92230f1660e5d0e69ca15b357638))
 - **FIX**: core test and statistics phone dashboard. ([655d2c82](https://github.com/growerp/growerp/commit/655d2c82a081a38e9a02c476dfe57626f634ef14))
 - **FIX**: revenue/expense report values and colors. ([aebd0ff8](https://github.com/growerp/growerp/commit/aebd0ff8ff0aa92f0e9a8fd6cc7c7811292df5e9))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: order_accouting integration tests. ([6c14fdd8](https://github.com/growerp/growerp/commit/6c14fdd8aac72fcb8e7caed51259a1bb2c8f009b))
 - **FIX**: errors in integrations test of the order_accounting package. ([aa229011](https://github.com/growerp/growerp/commit/aa2290116d2470479ed64795d7ecd6e3bc1f0159))
 - **FIX**: missed files from last 2 commits. ([d9b6a248](https://github.com/growerp/growerp/commit/d9b6a248cdd17a5490040c1ebc1cb43e42f2690f))
 - **FIX**: order_accounting automated tests. ([bc1498fc](https://github.com/growerp/growerp/commit/bc1498fc4a9c2e517daff92d92c9d188d562498f))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: context warning. ([909212af](https://github.com/growerp/growerp/commit/909212af8e05c23004ba34efc6fe520ae6b266c7))
 - **FIX**: various errors in screens. ([b8f0f973](https://github.com/growerp/growerp/commit/b8f0f973e3c9d416eb82f3525751dac4844c8145))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: order rental test. ([0f7967dc](https://github.com/growerp/growerp/commit/0f7967dc9036920ea54172aef95fb8d54958dee2))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: outreach order-accounting website automated tests. ([1f1b70f8](https://github.com/growerp/growerp/commit/1f1b70f8f80ed0b4de71eb74d3fe00912aa1bc36))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: basic tests of order_accounting, activity. ([7dfc0ffc](https://github.com/growerp/growerp/commit/7dfc0ffccea352ba09f1b30f000ce8c52825c12d))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: update FinDoc dialog behavior to return updated documents to the originating list on success. ([cfc1d17c](https://github.com/growerp/growerp/commit/cfc1d17c77426c950c472e140da423d231be5768))
 - **FIX**: add logout to tests will show if they succeed. ([b30ba898](https://github.com/growerp/growerp/commit/b30ba89826419ae8591e8122e70cd1771a384983))
 - **FIX**: update printing dependency version across multiple packages. ([b30da509](https://github.com/growerp/growerp/commit/b30da509c125bdd7f2b59233a42cecc6f22a6a75))
 - **FIX**: update last commit. ([e10d565c](https://github.com/growerp/growerp/commit/e10d565cc7ceec6e87427898ea2ad5a5eaaec2a4))
 - **FIX**: upload invoice via browser. ([6353a967](https://github.com/growerp/growerp/commit/6353a9671ceb9000969bb784202041cd1fe292ae))
 - **FIX**: update visibility keys and improve layout in user dialog and popup components for integration test. ([c1edbbf8](https://github.com/growerp/growerp/commit/c1edbbf8947e7874746a80d15c5814f4e10c04af))
 - **FIX**: various corrections on previous merge from Jules. ([dfcc02a8](https://github.com/growerp/growerp/commit/dfcc02a8869a0290c9cc0415d4d0d1f1d49d138a))
 - **FIX**: glaccount dialog debit/credit. ([ce4db6ec](https://github.com/growerp/growerp/commit/ce4db6ecc96a211f15f9c3aca4b6cd045fdfc1b2))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: prompt for subscription payment improved, only work when stripe API key present for owner 100000=GrowERP irself. ([60ce71ab](https://github.com/growerp/growerp/commit/60ce71ab7d40c76c64701ffd3973480d5aef66ac))
 - **FIX**: when thai language selected show the buddist year. ([6e998fb4](https://github.com/growerp/growerp/commit/6e998fb4c44377a62ad17d3aaff3cc7bd69e75b5))
 - **FIX**: missing translations in accounting. ([35c25372](https://github.com/growerp/growerp/commit/35c253724df71b41bed80e776e4a3e40799a0e50))
 - **FIX**: remove l10n app files. ([870b9ce4](https://github.com/growerp/growerp/commit/870b9ce469dc53a20a782cf3d31eb706f8761151))
 - **FIX**: missing request dialog translation. ([be962f84](https://github.com/growerp/growerp/commit/be962f84f32f05d485c07fac3a94672694250882))
 - **FIX**: hotel automated tests. ([a988acff](https://github.com/growerp/growerp/commit/a988acffe98905716be6999c02156c1e263717a7))
 - **FIX**: belongs to last commit. ([afd1b9da](https://github.com/growerp/growerp/commit/afd1b9dadfcca02cd476e8a69eeba14adba156e1))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: financial docs tests after adding localizations. ([bb573ee1](https://github.com/growerp/growerp/commit/bb573ee1e622a3fa93cd5f0a792c38aaba1f227e))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: order rental tests. ([1eae473f](https://github.com/growerp/growerp/commit/1eae473fc385e5136d10927f7c610d0a50dbaaf8))
 - **FIX**: improve error handling in getDioError and update SnackBar display in HelperFunctions. ([4d725096](https://github.com/growerp/growerp/commit/4d7250967022985bf935142aecea2e512addaed4))
 - **FIX**: backend notification and add doc. ([c95721ac](https://github.com/growerp/growerp/commit/c95721ac24beec00ef7038a099d16d0806a84779))
 - **FIX**: on a payment dialog fix an exeption when gateway repons return a null value for amount also add a secondary line when there is a reponse message. ([1440c863](https://github.com/growerp/growerp/commit/1440c863e96b66a3763626372fd2c71bb83b3d01))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FIX**: various fixes for the Stripe payment gateway payment buttons. ([5e141e4c](https://github.com/growerp/growerp/commit/5e141e4c4a9b22cde0436fe056cda716dfc10897))
 - **FIX**: new registrations got stuck after creditcard entry and Stripe enabled in the GrowERP initial company. ([18053bd8](https://github.com/growerp/growerp/commit/18053bd801947e5fdcae1c522669b506df267dbf))
 - **FIX**: update reservation dialog with header and field decoration. ([690db5d0](https://github.com/growerp/growerp/commit/690db5d0ead673df8b6495b4a508489fc3030762))
 - **FIX**: remove duplicate hero keys. ([866c4243](https://github.com/growerp/growerp/commit/866c4243fe5513b7983f319233abb939a645f947))
 - **FIX**: user dialog delete button/upload/list, upgraded printing for firestore studio. ([a6eec3dc](https://github.com/growerp/growerp/commit/a6eec3dcd700c345b3929a5af420d7343aaf1c76))
 - **FIX**: various fixes and enhancements of the hotel app. ([5f666f52](https://github.com/growerp/growerp/commit/5f666f527b6dcfd8dbeca40abd91887728a06d32))
 - **FIX**: hotel integration tests. ([d990be37](https://github.com/growerp/growerp/commit/d990be37a025eb33b6e99ce597d4de43a139b56d))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([93216258](https://github.com/growerp/growerp/commit/932162588cac34b8689ab5eeb8fecb1a2d38153a))
 - **FIX**: request test. ([fa2f7422](https://github.com/growerp/growerp/commit/fa2f7422346203f6032891eb2fd8f9385f2189e0))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: reorganized companyuser tests. ([e62c46c0](https://github.com/growerp/growerp/commit/e62c46c0056b40821d239a6bee8b8cc4e1de93b2))
 - **FIX**: automated integration test for ledger transactions. ([1ae7e18e](https://github.com/growerp/growerp/commit/1ae7e18e365b9ffdb43fa811d0da58b0a53d70ed))
 - **FIX**: position of floating buttons on larger than phone screens. ([183a3437](https://github.com/growerp/growerp/commit/183a3437a1af689a5aeebaaafa2e5dbed03ffc1d))
 - **FIX**: conversion split closing of documents in parts. ([80a97d7f](https://github.com/growerp/growerp/commit/80a97d7f9a9aa0c7140cf719f0144c8abdb24484))
 - **FIX**: dart lint and log warnings. ([4221d8b7](https://github.com/growerp/growerp/commit/4221d8b7e1a7508bf46bfead40f46dff2845d7a7))
 - **FIX**: purchase invoice test. ([778f235f](https://github.com/growerp/growerp/commit/778f235fbe4c4958a40483c3c2d990f98313e555))
 - **FIX**: change conversion quantities and lint error. ([f6f2cf08](https://github.com/growerp/growerp/commit/f6f2cf08948d1a5877d954ccad8597ff078a9f92))
 - **FIX**: conversion changes: close and update period totals by year. ([3bc65040](https://github.com/growerp/growerp/commit/3bc650402a20941c1d16ae0f8791c22c2ce545aa))
 - **FIX**: integration tests. ([16d23365](https://github.com/growerp/growerp/commit/16d233658c786b44de8607c1edb875b4cc03a1e4))
 - **FIX**: automated integrations tests, last fixes? ([e90ffa8d](https://github.com/growerp/growerp/commit/e90ffa8dfb514fb9fabb604a347405ac464fb918))
 - **FIX**: more integrated test corrections. ([047db5ce](https://github.com/growerp/growerp/commit/047db5ce6adf28a069ad3911983945cd6c3e460f))
 - **FIX**: more test corrections. ([0706aada](https://github.com/growerp/growerp/commit/0706aadac60106447fd1016615932bf10af571f7))
 - **FIX**: moqui update Dockerfile, add email birdsend parameters. ([4c7420a9](https://github.com/growerp/growerp/commit/4c7420a9aff8d6b8a96e040c2b36c7924a30b4e0))
 - **FIX**: purchase payment test. ([fa9eecf3](https://github.com/growerp/growerp/commit/fa9eecf3b4f3e2485d8fc7fcd2b5e6add797d9d2))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**: room rental and opporunity test. ([8eb70f4e](https://github.com/growerp/growerp/commit/8eb70f4e40bb0a62a7f881d43ba6f88bee102a45))
 - **FIX**: revenue/expense report. ([13a33191](https://github.com/growerp/growerp/commit/13a331919470fbc12fa442d9eadbab668f39a5b1))
 - **FIX**: payment purchase test. ([f96e7026](https://github.com/growerp/growerp/commit/f96e70262797f6edd3d7b4ec5e3d7b267398f584))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**: floating action buttons now relative from the bottom right of the screen(instead of top/left), so better show on the desktop. ([5f16c849](https://github.com/growerp/growerp/commit/5f16c84918f5f2db0e500097a962446fddb7ae87))
 - **FIX**: show placed/approve date instead of creation date when available. ([e5304a01](https://github.com/growerp/growerp/commit/e5304a01a800e606d0bbffac8831f85944f5e0a9))
 - **FIX**: build error & cleanup. ([0ed97436](https://github.com/growerp/growerp/commit/0ed974361b2524e9302993b60cf43bcad86aa947))
 - **FIX**: conversion & UI enhancements. ([e6620533](https://github.com/growerp/growerp/commit/e6620533ebf47cd7c01043587d9681d7a983dcd3))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: occupancy check in order rental. ([e6fb7962](https://github.com/growerp/growerp/commit/e6fb796252455483d21783bdcac788db4553bda4))
 - **FIX**: revenue report and various floating buttons positions. ([e3bb2069](https://github.com/growerp/growerp/commit/e3bb2069e3998ef4581a9372401e89fbbf33d905))
 - **FIX**: glaccount up/download. ([1e456a90](https://github.com/growerp/growerp/commit/1e456a90b76d0529f1082d7bda076c2a685ca89d))
 - **FIX**: conversion import correction, with userinterface adjustments in inventory/assets/locations. ([e08d9f08](https://github.com/growerp/growerp/commit/e08d9f088bb1a71ef1a53d9af825980d6136b7fa))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: health request form adjustments. ([ecb6cb7d](https://github.com/growerp/growerp/commit/ecb6cb7d02ffcb1954af3d180daddc9fe81e1418))
 - **FIX**: remove confusion of having the same data records in 2 files. ([94a32623](https://github.com/growerp/growerp/commit/94a3262306e1156bec6522796fd87e5b60c958df))
 - **FIX**: health app telephone. ([52fbf916](https://github.com/growerp/growerp/commit/52fbf916a9447a51b37fc4a5d92dc1d3c5029eba))
 - **FIX**: when only zero values on revenue/expense reports show a message instead of zero values. ([2aa45fc6](https://github.com/growerp/growerp/commit/2aa45fc6570ebb693a15714b59253550e6d1182d))
 - **FIX**: adjust gateway response for phone sized screen. ([8172cc38](https://github.com/growerp/growerp/commit/8172cc3826cf963480fbf5eba6e5d3d610bc89d4))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([cc48d8fe](https://github.com/growerp/growerp/commit/cc48d8fe4144b55c23f6f3633537d612e595e286))
 - **FEAT**: added a credit card capture for a trial period, updated tests. ([f6b2123b](https://github.com/growerp/growerp/commit/f6b2123b672407300bb3207a3955f64c16310473))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: added original payment amount and currency, fixed change radio to switch button on Transaction(flutter -> 3.55). ([42cb43c7](https://github.com/growerp/growerp/commit/42cb43c74269521f502891a6de7be6b94a6ecdfe))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**(l10n): Translate growerp_order_accounting package to Thai. ([bc30ed96](https://github.com/growerp/growerp/commit/bc30ed963cd0baacf2d55bf44d75114ae2200238))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**(l10n): Localize growerp_order_accounting to Thai. ([3759002c](https://github.com/growerp/growerp/commit/3759002c4e487ac227b46fbb85882f77dec8a5df))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**(rental): rental vertical app with cars/equipment demo data. ([90425783](https://github.com/growerp/growerp/commit/9042578306b1de6dbd2c53655c4ea911bc204930))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**(hotel): seasonal rates, web booking, housekeeping, occupancy reports. ([5401b59a](https://github.com/growerp/growerp/commit/5401b59a4e170470503bc8819f3a96d5a968ed1c))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: added invoice upload screens in purchase invoices (gemini link not yet working). ([d1513392](https://github.com/growerp/growerp/commit/d1513392beeff600a25843412b603a5ebabbbe3d))
 - **FEAT**: first version of the assesment package. ([c57ae654](https://github.com/growerp/growerp/commit/c57ae6541cb41dcedb1e15a0eb780a55b31137cd))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: now we have more space move the accounting option in the main menu. ([76788dbb](https://github.com/growerp/growerp/commit/76788dbbc4214e28f7cab4cfef8f8908830bcec4))
 - **FEAT**: added an AIprompt button on all windows, AI apikey can be set at accounting/systemSetup. ([90ecb38f](https://github.com/growerp/growerp/commit/90ecb38fbc85a77ca4012afbb8d6f26bec260f9e))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: improve design of list/detail screens of catalog, order/accounting and inventory. ([ebb9bb56](https://github.com/growerp/growerp/commit/ebb9bb5637ff25a4c8a68cbcfb9f2a49879ee3da))
 - **FEAT**: added the revenue/expense line chart. ([7e9e37db](https://github.com/growerp/growerp/commit/7e9e37dbd854570c24607987ee103821c4107c8f))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**(marketing): Create marketing app with extended dashboard. ([71b20859](https://github.com/growerp/growerp/commit/71b20859ee7d7381fb5cb83d5e2d33887692ea63))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: Implement HTTP response caching with `dio_cache_interceptor`, configurable cache duration, and cache invalidation on logout and mutating requests. ([adece8f9](https://github.com/growerp/growerp/commit/adece8f919faa3be095382c02ddc2c5621a5f5e7))
 - **FEAT**: first version of the Elearner app. ([2179a602](https://github.com/growerp/growerp/commit/2179a6022771871f4616115ee97eb01fdfab229b))
 - **FEAT**: enhance printing functionality and integrate FinDoc state management. ([f0dd196d](https://github.com/growerp/growerp/commit/f0dd196d1a82e8a7e6a99298d7e3b1e82d7726fc))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: dashboard enhancements. ([44b40b5d](https://github.com/growerp/growerp/commit/44b40b5df4158a15cfec1866ac276c14b0f633a6))
 - **FEAT**: show product information on transaction screen. ([092995d2](https://github.com/growerp/growerp/commit/092995d2d3830d16a20a979487ed7967ff7ac627))
 - **FEAT**: added routing and industry specific manufacturing. ([eb6374d9](https://github.com/growerp/growerp/commit/eb6374d96fa64c99da9a167dd7786dca08c82c97))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**: add Android Home Widget support to display accounting ledger charts. ([a39d7143](https://github.com/growerp/growerp/commit/a39d71434f58bd29d3e016491956451c9ca5e9ca))
 - **FEAT**: add Accounting Widget and related components for iOS. ([328b9432](https://github.com/growerp/growerp/commit/328b94329363e399cd254894567122a82461f5f1))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**: Extended main menu for Tasks and Freelance dashboard. ([531c9836](https://github.com/growerp/growerp/commit/531c983698823673b7f6b29c5674255b5cdf5b3b))
 - **FEAT**: open operational screens from the ADK chat assistant. ([f4533f0b](https://github.com/growerp/growerp/commit/f4533f0b1f8b3ba0a8f738b31d007436c4a87612))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **DOCS**: actualize app and building-block README files. ([1d0c980a](https://github.com/growerp/growerp/commit/1d0c980a326734bffc3afbe6e000bb38505d2ef9))

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

