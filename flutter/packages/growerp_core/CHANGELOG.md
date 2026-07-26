## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers); lengthen pubspec description.

## 1.11.0

 - **REFACTOR**: remove redundant ScaffoldMessenger from HomeForm and RegisterUserDialog: registration message was not showing. ([8dface8f](https://github.com/growerp/growerp/commit/8dface8f4bb8a5baa2c3f61cf2feb11a8a2870c0))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**(flutter): support optional full-screen rendering for UserDialog and CompanyDialog. ([7de30fdd](https://github.com/growerp/growerp/commit/7de30fddeeff689f96efdb1624151057c11d1f6e))
 - **REFACTOR**: standardize dialog components by integrating popUp widget and updating navigation and layout across packages. ([f13a4e06](https://github.com/growerp/growerp/commit/f13a4e0636b62d459dc78aa4081f8584540a7ea4))
 - **REFACTOR**: convert user and company routes to modal dialogs using DialogPage and update navigation logic to support overlay push. ([23768fe1](https://github.com/growerp/growerp/commit/23768fe15ed82bd222de449020fad30c6aa5678b))
 - **REFACTOR**: move growerp_chat package to core and update core dependencies accordingly. ([ee81f96b](https://github.com/growerp/growerp/commit/ee81f96bbb5be43ef337da616ec1fe8754603a2f))
 - **REFACTOR**: remove post-login onboarding assistant. ([84741be1](https://github.com/growerp/growerp/commit/84741be13dfbedde801227a864ca42bd51db0356))
 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([a07efb53](https://github.com/growerp/growerp/commit/a07efb537bab9e6eefb106bdf8bd4b389de8e5e1))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([38d4b563](https://github.com/growerp/growerp/commit/38d4b56396e127a2aaad96ee7ffb9b07e2501742))
 - **REFACTOR**: fix various integration tets, improve testing robustness, update test data, and handle missing menu configurations gracefully. ([e3a9b3e9](https://github.com/growerp/growerp/commit/e3a9b3e915f31f122a513c04dc348b76c3dc5c9d))
 - **REFACTOR**: replace Container with Material widgets in popup components to ensure proper ink response styling: github action failing. ([0c06aaf4](https://github.com/growerp/growerp/commit/0c06aaf45aae261f76346c570157a4f6a266b537))
 - **REFACTOR**: replace list view with styled data table for responsive agent configuration management. ([39c6ba22](https://github.com/growerp/growerp/commit/39c6ba2282a68137e69868274250c01fa024225f))
 - **REFACTOR**: disable PWA service workers in web builds, resolve stale cache issues, and fix assessment flow navigation and session token persistence. ([0092d542](https://github.com/growerp/growerp/commit/0092d542822ff425dacbbd73bce3be921db3da39))
 - **REFACTOR**: move the getting backend url into the core package. ([cc3f4a5e](https://github.com/growerp/growerp/commit/cc3f4a5eb6d98e3943da4c442a647e105d9b92b0))
 - **REFACTOR**: remove dynamic menu item management features and associated dialogs. ([47d371f1](https://github.com/growerp/growerp/commit/47d371f145e2f3c11fba59898f50d6ef67c9db93))
 - **REFACTOR**: Remove overloading of apiKey by creating loginStatus for authentication flow. ([d4728e99](https://github.com/growerp/growerp/commit/d4728e99707c6fe13cd3df897188f9f8f24b3009))
 - **REFACTOR**: update subscription dialog to dynamically fetch and display product plans from DataFetchBloc. ([fd01461e](https://github.com/growerp/growerp/commit/fd01461e3d2ff0d4247c2fe3f8b765636816f165))
 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: Replace DropdownSearch with Autocomplete in detail dialogs and refactor list displays with new styled data widgets for the order-accounting and catalog packages. ([0653340a](https://github.com/growerp/growerp/commit/0653340a354cf67d117830e3d8ea9799a1b73336))
 - **REFACTOR**: Remove localization dependency from CompanyUserBloc and update messages. ([f4883b6f](https://github.com/growerp/growerp/commit/f4883b6fe45c2bc86ff60cf01f0270037f00b917))
 - **REFACTOR**: centralize and improve authentication message display in `TopApp` with retry logic and update `mcp_dart` dependency. ([d9c5efb4](https://github.com/growerp/growerp/commit/d9c5efb421aacd7e33ee950e6775b4834ac97ef8))
 - **FIX**: improved manufacturing demo. ([a510c3fe](https://github.com/growerp/growerp/commit/a510c3fe7a75ed16dbb133dc7c9c25d8b9aeb516))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**(tests): robust desktop reopen + tab label for user_company. ([7784e381](https://github.com/growerp/growerp/commit/7784e3815aac147a46c0ce8fa963fb53c29b8dfe))
 - **FIX**: register new company. ([0209f542](https://github.com/growerp/growerp/commit/0209f5420535c16da9e6ced2a601873412976e44))
 - **FIX**(ci): unmask summarize failures and fix the tests behind them. ([dcc464eb](https://github.com/growerp/growerp/commit/dcc464eb8aeb7fdc641d7459bd6af7fad48de6f1))
 - **FIX**: ListFilterBar mobile — search field + actions on one line. ([db53f6b9](https://github.com/growerp/growerp/commit/db53f6b981bad81dec8b31c04f686e7bcef9cce4))
 - **FIX**: keep logout/chat-FAB on the main menu only (sub-screens use Home). ([5fdcc2ae](https://github.com/growerp/growerp/commit/5fdcc2ae807987d02564ebc48cda53beee9bf416))
 - **FIX**: logout on every screen; AI-chat FAB only on the main menu (core). ([54f5ea04](https://github.com/growerp/growerp/commit/54f5ea0417afdeea0b96163af7dead09cb5a2b21))
 - **FIX**: chat create opens a real, prefilled new-record form (Phase 2). ([a477a3ff](https://github.com/growerp/growerp/commit/a477a3ffcfc3727fa2d6f5d7bd543c5a9125e3f8))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([8ca44b0c](https://github.com/growerp/growerp/commit/8ca44b0c77cd29d4c633fa9a7154a5b8e2dca14e))
 - **FIX**: more automated test corrections. ([644aed1c](https://github.com/growerp/growerp/commit/644aed1c9ac8f91e672372f90a70f10e61c91719))
 - **FIX**: improve integration test reliability, asset test/glaccount test. ([99cda03b](https://github.com/growerp/growerp/commit/99cda03b7a6397854b21fb422c9444e3d1c6146f))
 - **FIX**: user test. ([d72985dc](https://github.com/growerp/growerp/commit/d72985dc5a664bf75f9651e74df154ff0ad2952c))
 - **FIX**: hotel test. ([6674fd00](https://github.com/growerp/growerp/commit/6674fd0089736cf2ec890d8bb98758eac381399e))
 - **FIX**(test): resolve integration test hang and fix example build errors. ([996e76f7](https://github.com/growerp/growerp/commit/996e76f79f8a510767ecc8c723aa6f699b5846b0))
 - **FIX**: doNewSearch scrolls the result list, not the search field. ([20a7895b](https://github.com/growerp/growerp/commit/20a7895b8f0d3c3890844b3150acd5b4ab792895))
 - **FIX**: reliably mark app used via dedicated register#AppUsed endpoint. ([f001de42](https://github.com/growerp/growerp/commit/f001de425c030bb5a53e5e29655bac652eff1f61))
 - **FIX**: show welcome + assessment only on first login. ([0eb67623](https://github.com/growerp/growerp/commit/0eb676235d20457c22e1aed523c130d535c902d8))
 - **FIX**: upgrade file_picker to remove warning message. ([78a1c283](https://github.com/growerp/growerp/commit/78a1c283fc25edfd6aa12cd880626bb53bebed06))
 - **FIX**: more integrated test corrections. ([047db5ce](https://github.com/growerp/growerp/commit/047db5ce6adf28a069ad3911983945cd6c3e460f))
 - **FIX**: skip AI onboarding assistant when no Gemini key is configured. ([ea73237f](https://github.com/growerp/growerp/commit/ea73237fe3783aba64c027f5faedc4c39843afa2))
 - **FIX**: automatically dismiss onboarding assistant after login in integration tests. ([e3bb5e6e](https://github.com/growerp/growerp/commit/e3bb5e6e48296de00ab79fe41a5405bdf3d52bb9))
 - **FIX**: upgraded and fixed the chat function. ([1909eb76](https://github.com/growerp/growerp/commit/1909eb7673ebb3964ebf410d5df5aa17ad31de02))
 - **FIX**: ADK chat offers System Setup when LLM key missing; key now applies. ([3507c0d7](https://github.com/growerp/growerp/commit/3507c0d71a6c35b3032f8432d46d5b21e663bbe6))
 - **FIX**: update chat badge in real-time without page change. ([d50775e2](https://github.com/growerp/growerp/commit/d50775e242d23bad866bf9567b65f215359ef358))
 - **FIX**: key autocomplete option tiles so test taps by Key, not coordinates. ([5cd2ef54](https://github.com/growerp/growerp/commit/5cd2ef541f0c0b2332426e537eb36bceb285d99f))
 - **FIX**: asset dialog close race + search poll early-exit + endless pagination guard. ([43d9b715](https://github.com/growerp/growerp/commit/43d9b7156969016fb62b58bab473d9eac9d904ce))
 - **FIX**: wait for async autocomplete options before selecting (gl_account 99901 create race). ([3b11385a](https://github.com/growerp/growerp/commit/3b11385a13aaf445660a3e8c8866174307bb582a))
 - **FIX**: prevent doNewSearch from tapping wrong row on slow CI. ([0408f83e](https://github.com/growerp/growerp/commit/0408f83ebf062147eb01effdbfb0e9aada22d572))
 - **FIX**: missing version in pubspec. ([25046dd9](https://github.com/growerp/growerp/commit/25046dd905a9d9172672952834a7bf37720707a9))
 - **FIX**: more test corrections. ([0706aada](https://github.com/growerp/growerp/commit/0706aadac60106447fd1016615932bf10af571f7))
 - **FIX**: replace retired gemini-2.0-flash with gemini-2.5-flash. ([22acfd58](https://github.com/growerp/growerp/commit/22acfd58179d1e8f01dae5b4c1aad1de3617b389))
 - **FIX**: automated integrations tests, last fixes? ([e90ffa8d](https://github.com/growerp/growerp/commit/e90ffa8dfb514fb9fabb604a347405ac464fb918))
 - **FIX**: request test. ([fa2f7422](https://github.com/growerp/growerp/commit/fa2f7422346203f6032891eb2fd8f9385f2189e0))
 - **FIX**: gl_account test. ([781d81a6](https://github.com/growerp/growerp/commit/781d81a63566613c765c9c30ef286500b0387330))
 - **FIX**: registration_login_test.dart. ([b45d48e0](https://github.com/growerp/growerp/commit/b45d48e0d9532519f93e675a4954a1352f6c892e))
 - **FIX**: prevent infinite rebuild loop in display menu options by memoizing injected configurations and disable builtInKotlin in Android gradle properties. ([96ec2454](https://github.com/growerp/growerp/commit/96ec2454ff151c7298d880e6be59fc5a22a2a1d1))
 - **FIX**: reorganized companyuser tests. ([e62c46c0](https://github.com/growerp/growerp/commit/e62c46c0056b40821d239a6bee8b8cc4e1de93b2))
 - **FIX**: position of floating buttons on larger than phone screens. ([183a3437](https://github.com/growerp/growerp/commit/183a3437a1af689a5aeebaaafa2e5dbed03ffc1d))
 - **FIX**: set menu name, add test file validation in CI, and clear stale API key in registration test. ([7bfef6b0](https://github.com/growerp/growerp/commit/7bfef6b0a4095a489dcca387447b763f80b5d9a9))
 - **FIX**: ui improvements and dart generall fixes. ([5551f7a3](https://github.com/growerp/growerp/commit/5551f7a36fd88d061edf0960746e7fa07f644534))
 - **FIX**: wrap grouping decorator content in Material widget and add generated macOS ephemeral configuration files. ([5dcdb5e8](https://github.com/growerp/growerp/commit/5dcdb5e89376e8e25d151188bfb6c0e7b6e141d3))
 - **FIX**: automated tests. ([770bb01b](https://github.com/growerp/growerp/commit/770bb01bde8cb950ed897bf09a6b04f14c61d6e5))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([72507cc3](https://github.com/growerp/growerp/commit/72507cc3718b40cebde50062ba2aec40525eab6b))
 - **FIX**(nav): keep nav rail labels on one line. ([e116626f](https://github.com/growerp/growerp/commit/e116626f891e0da5a7207972e5a1038c5c803c55))
 - **FIX**: implement chat room websocket subscription cleanup and recovery on authentication state changes. ([8ea4128f](https://github.com/growerp/growerp/commit/8ea4128f2e0ef8e504152756c8c062fd498aed22))
 - **FIX**: update application ID to com.example.example across example Android build configurations. ([dbf96c32](https://github.com/growerp/growerp/commit/dbf96c32f3d3b60c5ba007ad9d8a9ff8dca89365))
 - **FIX**: automated integration test for ledger transactions. ([1ae7e18e](https://github.com/growerp/growerp/commit/1ae7e18e365b9ffdb43fa811d0da58b0a53d70ed))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: room rental and opporunity test. ([8eb70f4e](https://github.com/growerp/growerp/commit/8eb70f4e40bb0a62a7f881d43ba6f88bee102a45))
 - **FIX**(tests): pin readyTarget element + layout-aware asset status label. ([890e26a7](https://github.com/growerp/growerp/commit/890e26a7a8107852bc4672d43a83e8283602effb))
 - **FIX**: move menu restore button. ([b1cd3c9f](https://github.com/growerp/growerp/commit/b1cd3c9ff45229d5770027bdaf05fedf41bb6e38))
 - **FIX**(adk): use authenticated user ID instead of hardcoded 'flutter-user'. ([9cca7f29](https://github.com/growerp/growerp/commit/9cca7f29548891e7067bfc4c76cc22744957aa00))
 - **FIX**: glaccount up/download. ([1e456a90](https://github.com/growerp/growerp/commit/1e456a90b76d0529f1082d7bda076c2a685ca89d))
 - **FIX**: now use growerp.com for base url, restore scaffold in home_form. ([af4c56f4](https://github.com/growerp/growerp/commit/af4c56f4b81f335ef1cdcfecea0395e90e87d1ca))
 - **FIX**: replace material banner. ([ed475261](https://github.com/growerp/growerp/commit/ed47526167ef380f0efb11a8d95f3a703b33d411))
 - **FIX**: adjust backend url. ([f28bfc7d](https://github.com/growerp/growerp/commit/f28bfc7d7d1f736adc8cbf3987c670412ada8e57))
 - **FIX**: update onboarding dialog header and enhance menu preview card submission logic. ([b609275c](https://github.com/growerp/growerp/commit/b609275cfb7dc619806e8cbaf0057b4143dc9f80))
 - **FIX**: lead tests. ([ec992d86](https://github.com/growerp/growerp/commit/ec992d8626480b9e4f41ce387f3ea4ea8dee95e2))
 - **FIX**(tests): repair long-standing desktop/mobile integration test failures. ([3ad7b9f8](https://github.com/growerp/growerp/commit/3ad7b9f88361d94c6b9147a05fe1a27f825c36ba))
 - **FIX**: integrate trial welcome flow, refine onboarding prompt logic, and update automated integration tests. ([e292b66b](https://github.com/growerp/growerp/commit/e292b66b1fbf0e44f0ac72ed133ed5f671f889c8))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: removed the workflow functionality. ([97c9ee60](https://github.com/growerp/growerp/commit/97c9ee606ec1f74fb4a7e3faf804e290ac08c5fd))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: login with the return key in the web version. ([d63e6f63](https://github.com/growerp/growerp/commit/d63e6f634374b708fc59663412bbe0fe3c9ae807))
 - **FIX**: hotel tests and faults. ([7b05f70e](https://github.com/growerp/growerp/commit/7b05f70e9bd3e0a946526c02f1e54bbbe75b5238))
 - **FIX**: user dialog delete button/upload/list, upgraded printing for firestore studio. ([a6eec3dc](https://github.com/growerp/growerp/commit/a6eec3dcd700c345b3929a5af420d7343aaf1c76))
 - **FIX**: remove duplicate hero keys. ([866c4243](https://github.com/growerp/growerp/commit/866c4243fe5513b7983f319233abb939a645f947))
 - **FIX**: prompt for subscription payment improved, only work when stripe API key present for owner 100000=GrowERP irself. ([60ce71ab](https://github.com/growerp/growerp/commit/60ce71ab7d40c76c64701ffd3973480d5aef66ac))
 - **FIX**: loading indicator not shown also not error messages on login sequence. ([22b43b0e](https://github.com/growerp/growerp/commit/22b43b0e4b479b368d834e26b5e0d5d7ab24a5d1))
 - **FIX**: check last payment not older than one month, allow one week to pay, improved login sequence, fixed reset password. ([883bc030](https://github.com/growerp/growerp/commit/883bc0301ff5a9fb6ca166bab94b7904638ac11d))
 - **FIX**: liner demo not showing revenue report. ([d84a6ea6](https://github.com/growerp/growerp/commit/d84a6ea61b1cbc95a6aab59392c44b6dd105ef9d))
 - **FIX**: missing mandatory root category for GrowERP itself when installed in test. ([04057865](https://github.com/growerp/growerp/commit/04057865387ad7d42b9d86343eb5963dfc861919))
 - **FIX**: subscription test & debugged function. ([eec77aba](https://github.com/growerp/growerp/commit/eec77abaf1f5102dfb078d1a1a334e625b3ea746))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FIX**: workorder dialog improved, removed debug messages. ([a405ee2b](https://github.com/growerp/growerp/commit/a405ee2bcffa18f4f3b4ba98b3b67507ae977a27))
 - **FIX**: more timezone corrections. ([31b0bb52](https://github.com/growerp/growerp/commit/31b0bb524553b8eee9411e8a9c59d592d210c0c4))
 - **FIX**: various integration tests. ([55be7bdd](https://github.com/growerp/growerp/commit/55be7bddc150e30e100e9d2194ce21762ad56fd9))
 - **FIX**: fixing general problems running tests on other than mobile devices, created general used demo message screen, catalog swag demo now run on Linux, should run on win and mac too. ([289a163c](https://github.com/growerp/growerp/commit/289a163cd38a92230f1660e5d0e69ca15b357638))
 - **FIX**: core test and statistics phone dashboard. ([655d2c82](https://github.com/growerp/growerp/commit/655d2c82a081a38e9a02c476dfe57626f634ef14))
 - **FIX**: corrected IOS and MacOS problems reported by the appstore. ([895e64c0](https://github.com/growerp/growerp/commit/895e64c051f046547629ed2c54862cb52de12fa7))
 - **FIX**: company lead test. ([b9702b3a](https://github.com/growerp/growerp/commit/b9702b3ae2e719363406077529eb5939467283d3))
 - **FIX**: support app should remember previous login when not logedout. ([e8bbcc60](https://github.com/growerp/growerp/commit/e8bbcc607e924eb8450931c86b9b50953eae9649))
 - **FIX**: enable dynamic dashboard card generation from menu items and display statistics for relevant routes. ([6ef1eb22](https://github.com/growerp/growerp/commit/6ef1eb220fc253a35c80a2a8a58126cd8520fca7))
 - **FIX**: web startup problem caused by import 'dart:io' show Platform; now replaced with import 'package:universal_io/io.dart';. ([2996147c](https://github.com/growerp/growerp/commit/2996147c5a4cbe27edacb723e7aa0db6abc1839b))
 - **FIX**: menu settings mixed up between logins. ([039972cc](https://github.com/growerp/growerp/commit/039972cc61f58a5fc774b95d023799f75ded8290))
 - **FIX**: app bar company not show dialog. ([077c33d0](https://github.com/growerp/growerp/commit/077c33d081a58a3178424b26e9a1c20101902788))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: order_accouting integration tests. ([6c14fdd8](https://github.com/growerp/growerp/commit/6c14fdd8aac72fcb8e7caed51259a1bb2c8f009b))
 - **FIX**: errors in integrations test of the order_accounting package. ([aa229011](https://github.com/growerp/growerp/commit/aa2290116d2470479ed64795d7ecd6e3bc1f0159))
 - **FIX**: update base URL handling for Android emulators to reach host machine on different url/ports. ([7d304f1e](https://github.com/growerp/growerp/commit/7d304f1eaf1bf3304a9d95415287744e7ddfe0a5))
 - **FIX**: missed files from last 2 commits. ([d9b6a248](https://github.com/growerp/growerp/commit/d9b6a248cdd17a5490040c1ebc1cb43e42f2690f))
 - **FIX**: backend notification and add doc. ([c95721ac](https://github.com/growerp/growerp/commit/c95721ac24beec00ef7038a099d16d0806a84779))
 - **FIX**: inventory integration tests. ([42c3b904](https://github.com/growerp/growerp/commit/42c3b9046a6a8dccb3052f6a817e2aa681ce9350))
 - **FIX**: order_accounting automated tests. ([bc1498fc](https://github.com/growerp/growerp/commit/bc1498fc4a9c2e517daff92d92c9d188d562498f))
 - **FIX**: improve error handling in getDioError and update SnackBar display in HelperFunctions. ([4d725096](https://github.com/growerp/growerp/commit/4d7250967022985bf935142aecea2e512addaed4))
 - **FIX**: package user_company intergration tests passed. ([3419f830](https://github.com/growerp/growerp/commit/3419f8304eb2897d0b1060c4edec54847b378750))
 - **FIX**: now all core tests pass, also headless. ([fce6aabc](https://github.com/growerp/growerp/commit/fce6aabca1c9f57a5853322e1a8b881a2ccf14ba))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: camera and image upload on company dialog. ([be1334ee](https://github.com/growerp/growerp/commit/be1334ee9b9e5f5d0f61ed4225a666bd10f4e495))
 - **FIX**: various test errors. ([132af2ba](https://github.com/growerp/growerp/commit/132af2ba5e2a0ccbb6b7a8c8d5756c620b7efaa7))
 - **FIX**: increase default timeout values for Dio client. ([188d6757](https://github.com/growerp/growerp/commit/188d67576bcea7dccc5ca80c5ddd7be1ea2500f5))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: core integration tests. ([f794d236](https://github.com/growerp/growerp/commit/f794d2361403ef907f0069622de7fee2d66414dc))
 - **FIX**: implement reload functionality for web  platforms in force update dialog. ([98d3b275](https://github.com/growerp/growerp/commit/98d3b2755461ea3bb672bd74cf11adbc7a171f2d))
 - **FIX**: enhance force update dialog for Linux users; add terminal command instructions and adjust button visibility. ([d0c64d82](https://github.com/growerp/growerp/commit/d0c64d824049a95efd25d14cd69a2d92426aed37))
 - **FIX**: enhance state management in dialogs and blocs; improve loading behavior and error handling: result of automated tests. ([746c9f1c](https://github.com/growerp/growerp/commit/746c9f1c605c0cf6119c7661de1d5c97108ae245))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: centralize image picking logic into `HelperFunctions` and enhance web loading screen UI with a circular logo container. ([a04a579a](https://github.com/growerp/growerp/commit/a04a579a2d5e6fd1b2f904907aa61fb77930f462))
 - **FIX**: translations inventory. ([fb345e4f](https://github.com/growerp/growerp/commit/fb345e4ff0ffeaf8ef59ef03fc5e7c0f1a55eee2))
 - **FIX**: user/company tests after adding localizations. ([8ebff37a](https://github.com/growerp/growerp/commit/8ebff37ae61361c04592c1803aba5613a464b27c))
 - **FIX**: show growerp logo at login screen. ([87ae8a42](https://github.com/growerp/growerp/commit/87ae8a42e24215d7f860a29aa75df2c4d7916262))
 - **FIX**: missing meta data and translations. ([39007490](https://github.com/growerp/growerp/commit/39007490db6566343568c79021d8be0a08324b46))
 - **FIX**: company image not showing. ([8b7a78b8](https://github.com/growerp/growerp/commit/8b7a78b899bd4f4a312c40d875e758b9edd65398))
 - **FIX**: localizations,docs , flutter linux install for AI. ([e2acae1a](https://github.com/growerp/growerp/commit/e2acae1ae49639bc77ed713471e25de66f6af230))
 - **FIX**: remove l10n app files. ([870b9ce4](https://github.com/growerp/growerp/commit/870b9ce469dc53a20a782cf3d31eb706f8761151))
 - **FIX**: when thai language selected show the buddist year. ([6e998fb4](https://github.com/growerp/growerp/commit/6e998fb4c44377a62ad17d3aaff3cc7bd69e75b5))
 - **FIX**: remove duplicate key, update reports. ([327d8a07](https://github.com/growerp/growerp/commit/327d8a0704a7a8407aef77d2a4e2b55941021d2c))
 - **FIX**: show password clears username, remember username in newuser, forget password. ([3a78bd6d](https://github.com/growerp/growerp/commit/3a78bd6d6cae42f28c39cc42d47e8f3403113912))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: dialog backgrounds. ([d0e4c770](https://github.com/growerp/growerp/commit/d0e4c770131c55762363539b8d2b13ccdfec4853))
 - **FIX**: various errors in screens. ([b8f0f973](https://github.com/growerp/growerp/commit/b8f0f973e3c9d416eb82f3525751dac4844c8145))
 - **FIX**: mobile dashboard cards text. ([75272954](https://github.com/growerp/growerp/commit/752729541234f3d43527f8af89aadb633754882b))
 - **FIX**: new company registrtion, more info screen. ([3b55b07d](https://github.com/growerp/growerp/commit/3b55b07d8141878e428fbc4c8897e67a4cea9e46))
 - **FIX**: add key to Center widget for better widget identification. ([37f09a1f](https://github.com/growerp/growerp/commit/37f09a1ff1221013f331e3948c0b93c06e3b2ffa))
 - **FIX**: glaccount dialog debit/credit. ([ce4db6ec](https://github.com/growerp/growerp/commit/ce4db6ecc96a211f15f9c3aca4b6cd045fdfc1b2))
 - **FIX**: Gracefully close Flutter WebSocket connections and refactor Moqui WebSocket endpoints to use direct service calls, improving Docker compatibility and error handling. ([c0a2ce30](https://github.com/growerp/growerp/commit/c0a2ce30b5f1872479ce4047b62fdcb8cd3787bb))
 - **FIX**: update key for OutlinedButton in UserDialog to improve widget identification. ([0e2fff68](https://github.com/growerp/growerp/commit/0e2fff68dec1cacc9470641dfde038be0c2f0a1c))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: update visibility keys and improve layout in user dialog and popup components for integration test. ([c1edbbf8](https://github.com/growerp/growerp/commit/c1edbbf8947e7874746a80d15c5814f4e10c04af))
 - **FIX**: fix core integration tests. ([3e512570](https://github.com/growerp/growerp/commit/3e512570f2b485bb73d818101a5167a9a4cd232f))
 - **FIX**: update printing dependency version across multiple packages. ([b30da509](https://github.com/growerp/growerp/commit/b30da509c125bdd7f2b59233a42cecc6f22a6a75))
 - **FIX**: improve integration test stability with `pumpAndSettle` and update navigation calls to use new route paths. ([aef9da76](https://github.com/growerp/growerp/commit/aef9da76474de36028269569b67001c27da56201))
 - **FIX**: website and purchase payment test. ([041e317b](https://github.com/growerp/growerp/commit/041e317bdda28487e66db59781802a680083531e))
 - **FIX**: Prevent duplicate trial welcome dialog display in tenant setup. ([9cca2572](https://github.com/growerp/growerp/commit/9cca257288373908c1ca2ed74663f03cdf2d2c36))
 - **FIX**: company_user_customer_test. ([5a7ad2c4](https://github.com/growerp/growerp/commit/5a7ad2c4feeb8a446c8a1cfacc51cb9c5056749a))
 - **FIX**: catalog integration tests. ([f4deb53f](https://github.com/growerp/growerp/commit/f4deb53f9a68e6f0d287f320b78e1baea6e0d38f))
 - **FIX**(tests): repair desktop-layout integration test failures. ([f72ae43c](https://github.com/growerp/growerp/commit/f72ae43ce6a315f9c3c5574c51f2d8fb9c78755e))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([77c05741](https://github.com/growerp/growerp/commit/77c057413402848b53122bf2d7039a85c7b039d4))
 - **FIX**: headless test improvement reversal". ([d5ee6b0e](https://github.com/growerp/growerp/commit/d5ee6b0e5b4e16f871900fc7f2d115505e2a917a))
 - **FIX**: show API key only  when not in release mode. ([15874b39](https://github.com/growerp/growerp/commit/15874b39735b672ab2bcd68ab1f233a584b79a27))
 - **FIX**: dynamic menu test. ([9158d362](https://github.com/growerp/growerp/commit/9158d3629c39e77c88641be7b9efa1880b3620ad))
 - **FIX**: verious fixes and started integration test around the landingpage/assessment. ([3f8777c0](https://github.com/growerp/growerp/commit/3f8777c07a281b9ba2de77178d5f1b37b2fdc31f))
 - **FIX**: assignment and landingpage maintenance now hand tested and fixed errors. ([96476ce9](https://github.com/growerp/growerp/commit/96476ce97cebef94fc400e863a5e4705b2642319))
 - **FIX**: landing page tested successfull with automated test. ([b800aad3](https://github.com/growerp/growerp/commit/b800aad331769cce5f83ae5ef4a2635c1056f5ee))
 - **FIX**: chatroom not read indicator. ([18333b50](https://github.com/growerp/growerp/commit/18333b504401544fefba2fc34cd09c411069e7ee))
 - **FIX**: more outreach automation fixes and tests. ([461a4da8](https://github.com/growerp/growerp/commit/461a4da80d3bc5d70d7acae4ba126bba5dfae7f2))
 - **FIX**: browsermcp now working in Linux out of the box, probable windows/MacOs and browser (with playwright and proxy server). ([7a6976fe](https://github.com/growerp/growerp/commit/7a6976fe1e25d05614a24b7a418ced7cfa11db3e))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: outreach order-accounting website automated tests. ([1f1b70f8](https://github.com/growerp/growerp/commit/1f1b70f8f80ed0b4de71eb74d3fe00912aa1bc36))
 - **FIX**: landingpage automated test succeeded. ([e8807c4d](https://github.com/growerp/growerp/commit/e8807c4dde1397dddde2178b48980a97cf6eaf42))
 - **FIX**: integrated tests: user_company, sales. ([f22cd5a0](https://github.com/growerp/growerp/commit/f22cd5a04f79ac48e9b60cd784ece24040853d0d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: basic tests of order_accounting, activity. ([7dfc0ffc](https://github.com/growerp/growerp/commit/7dfc0ffccea352ba09f1b30f000ce8c52825c12d))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: headless test improvement. ([e04b232f](https://github.com/growerp/growerp/commit/e04b232fa98bf2d189cd100d1b30c2d184713d5a))
 - **FIX**: all build and lint errors..TODO remained.... ([331ca65a](https://github.com/growerp/growerp/commit/331ca65aa3b66fe18c3853718be610404b55b641))
 - **FEAT**: Introduce styled data table components and common UI widgets for standardized list and detail views for the course,marketing and outreach packages,. ([b0417ed8](https://github.com/growerp/growerp/commit/b0417ed8ac11cfe565fdf45bdb879709dcfb74b2))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: creditcard payment only requested after evaluation period. ([9d7f1c0c](https://github.com/growerp/growerp/commit/9d7f1c0c64b4af667509745a0cf005df8758e58d))
 - **FEAT**: extended the growerp command for create/import/export package, check docs for detail.(PLEASE note Locale, changed to String otherwise could not use in CLI). ([3462be78](https://github.com/growerp/growerp/commit/3462be783d4e2b7553a43a2bf702b451189bd521))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: now we have more space move the accounting option in the main menu. ([76788dbb](https://github.com/growerp/growerp/commit/76788dbbc4214e28f7cab4cfef8f8908830bcec4))
 - **FEAT**: added a color picker to the user interface. ([c00b2fa6](https://github.com/growerp/growerp/commit/c00b2fa60e6d33c06c0b9f9c64fc81bdebe9035a))
 - **FEAT**: first version of the assesment package. ([c57ae654](https://github.com/growerp/growerp/commit/c57ae6541cb41dcedb1e15a0eb780a55b31137cd))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: Add `/user` route to display user profile as a standalone page and update authentication state upon user profile changes. ([1eaeea40](https://github.com/growerp/growerp/commit/1eaeea4003558c2fa8718466e738bf403ff680b5))
 - **FEAT**: Application UI graphical enhancements. ([2bb2c074](https://github.com/growerp/growerp/commit/2bb2c07489532dbef086017d899815875cb37b0f))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: enhance user registration to support multi-tenant creation and trial flows with dedicated services and UI. ([605d1f47](https://github.com/growerp/growerp/commit/605d1f476cc11f5469487d1de8baeff48748e4b5))
 - **FEAT**: Refactor trial/evaluation flow, update `apiKey` handling, and improve test stability by replacing `pumpAndSettle` with `pump` in integration tests. ([d6bd1d8f](https://github.com/growerp/growerp/commit/d6bd1d8f576b5564a7bcd467516c4ec80d55cd9c))
 - **FEAT**: Add drag-and-drop reordering and inline editing for child menu tabs, and refine menu item dialog closing behavior. ([468fae79](https://github.com/growerp/growerp/commit/468fae790c4e14a320cc53a78051e843bfc0ab6c))
 - **FEAT**: enhance WebSocket client connection handling, make connections asynchronous, and refine core integration tests. ([fe1e51f1](https://github.com/growerp/growerp/commit/fe1e51f194d1713308b0e0f3a1dec747c2f5e1a5))
 - **FEAT**: Upgrade mcp_dart to 1.2.0, migrate to McpClient, and ensure graceful WebSocket shutdown. ([a54ae83a](https://github.com/growerp/growerp/commit/a54ae83a5392f2f9a0544e6022f01688f509cea9))
 - **FEAT**: Update documentation dates, introduce new UI/theming and `go_router` navigation features, adjust test banner display logic, and clarify trial period in README. ([32363106](https://github.com/growerp/growerp/commit/32363106775cd84ac9ff8afaaef142c1583d7e47))
 - **FEAT**: set 'test' configuration flag in debug mode when backend URL is not provided. ([60f2a9ba](https://github.com/growerp/growerp/commit/60f2a9ba963ab5132449743abdb31495b3d2aeb7))
 - **FEAT**: Relocate trial welcome dialog to tenant setup, add fresh trial check, and enhance subscription status calculation for accuracy. ([e5be7ee5](https://github.com/growerp/growerp/commit/e5be7ee59f6f5860ff91f9aaad63ca25d2c4139d))
 - **FEAT**: enhance UI theming for popups and dialogs; update Gemini API integration. ([802c23c8](https://github.com/growerp/growerp/commit/802c23c857487d1bd0d90246fab1178322896715))
 - **FEAT**: added invoice upload screens in purchase invoices (gemini link not yet working). ([d1513392](https://github.com/growerp/growerp/commit/d1513392beeff600a25843412b603a5ebabbbe3d))
 - **FEAT**: first backend messages translated, see plan: docs/GrowERP_Backend_L10n_Quick_Reference.md. ([3b598fdc](https://github.com/growerp/growerp/commit/3b598fdcedc1528eb2fd95b11e5ee488c37a5956))
 - **FEAT**: Allow backend port (8080) to be configured via dart-define for clients and tests, and update dependencies. ([ee8a91f3](https://github.com/growerp/growerp/commit/ee8a91f3aa4879cc4252e61ac933a9ed65ca3a77))
 - **FEAT**: add course model to growerp_models package. ([fc412fa5](https://github.com/growerp/growerp/commit/fc412fa5efc59737694c3fc473cf586038a23ad6))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: Version Comparison Logic for forced update. ([a32deacd](https://github.com/growerp/growerp/commit/a32deacd98c5967659e9659695a6bfab9c087573))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: Introduce styled data table components and common UI widgets for standardized list and detail views for the core and companyuser components, integration tests success. ([ed18d7f5](https://github.com/growerp/growerp/commit/ed18d7f5efb5221867210e95c4906ba2b4041bbe))
 - **FEAT**: improve design of list/detail screens of catalog, order/accounting and inventory. ([ebb9bb56](https://github.com/growerp/growerp/commit/ebb9bb5637ff25a4c8a68cbcfb9f2a49879ee3da))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: Display company name in the rest request list and enable searching by user or company name. ([1c7f4175](https://github.com/growerp/growerp/commit/1c7f4175e867545e62424cba2222f21fbe50f59e))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: dynamically load all currencies from the backend and upgrade currency selection fields to use autocomplete. ([10752274](https://github.com/growerp/growerp/commit/10752274141937636720599be06fc670695adf3b))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**: added language selection to hime screen and thai translation to the core package. ([fa200fb4](https://github.com/growerp/growerp/commit/fa200fb4367faf1135665658240a36ea0d56a2ba))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**: Implement HTTP response caching with `dio_cache_interceptor`, configurable cache duration, and cache invalidation on logout and mutating requests. ([adece8f9](https://github.com/growerp/growerp/commit/adece8f919faa3be095382c02ddc2c5621a5f5e7))
 - **FEAT**: Add OwnerPersonRestRequest entity and REST API for fetching related data. ([f28e54f3](https://github.com/growerp/growerp/commit/f28e54f3a5e70a09c3b5cd3ba71454b14d284a36))
 - **FEAT**: add support for moquiSessionToken persistence in AuthBloc and Dio client. ([2f7a9fab](https://github.com/growerp/growerp/commit/2f7a9fab32d781ed05174182eba512474291cc79))
 - **FEAT**: Enhance XML Schema and website follow us Definitions. ([9539c19b](https://github.com/growerp/growerp/commit/9539c19b7d8e718b758aebcff2c375789f7581ea))
 - **FEAT**: social posting jobs. ([e824ad10](https://github.com/growerp/growerp/commit/e824ad10948150cd5628f1554c9905e5bacbf35b))
 - **FEAT**: added original payment amount and currency, fixed change radio to switch button on Transaction(flutter -> 3.55). ([42cb43c7](https://github.com/growerp/growerp/commit/42cb43c74269521f502891a6de7be6b94a6ecdfe))
 - **FEAT**: first version of the Elearner app. ([2179a602](https://github.com/growerp/growerp/commit/2179a6022771871f4616115ee97eb01fdfab229b))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: dashboard enhancements. ([44b40b5d](https://github.com/growerp/growerp/commit/44b40b5df4158a15cfec1866ac276c14b0f633a6))
 - **FEAT**: add routing to manufactoring. ([31b73c8e](https://github.com/growerp/growerp/commit/31b73c8e03011fcf128077fb0052827bce3e794d))
 - **FEAT**(agents): add wiki menu option with rich dashboard card. ([0d0ea93e](https://github.com/growerp/growerp/commit/0d0ea93e600772a64430942dfdbf6f606775319f))
 - **FEAT**: added routing and industry specific manufacturing. ([eb6374d9](https://github.com/growerp/growerp/commit/eb6374d96fa64c99da9a167dd7786dca08c82c97))
 - **FEAT**: added time zone support. ([f2978340](https://github.com/growerp/growerp/commit/f29783408547a3d4e9f962bd187e5eea52bd20d9))
 - **FEAT**: add unit of measure and amount to the product definition, restructuring and fixing product test. ([c2623bf4](https://github.com/growerp/growerp/commit/c2623bf416e98f34a166397bf5234801ba1dda6f))
 - **FEAT**: extend the subscriptions and show current growerp plan in accounting setup. ([cb99d898](https://github.com/growerp/growerp/commit/cb99d898a43245f3204a37496e3a64d37924842e))
 - **FEAT**: create the demo package to demonstrate system functionality. ([8d817855](https://github.com/growerp/growerp/commit/8d8178553697da54f3cee93fd611d91bf66742b7))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: VERY first version of subscriptions. ([2ca41795](https://github.com/growerp/growerp/commit/2ca41795b4de9181cded554d91a30bcc8779edc9))
 - **FEAT**: show test banner also in debug mode and on all pages. ([ca0aa92c](https://github.com/growerp/growerp/commit/ca0aa92c8ff13de00c4f5e0882931996d44f8558))
 - **FEAT**: added a credit card capture for a trial period, updated tests. ([f6b2123b](https://github.com/growerp/growerp/commit/f6b2123b672407300bb3207a3955f64c16310473))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **FEAT**: add trial expiry tests and update subscription days logic. ([8d993a52](https://github.com/growerp/growerp/commit/8d993a522b29f3e767de7646e309899596106b8b))
 - **FEAT**: add asset links for admin .support and hotel applications, enhance upgrade documentation with manual release steps. ([41a93a69](https://github.com/growerp/growerp/commit/41a93a69988fb53bcd4b3e7d7adfb270a2edf1f7))
 - **FEAT**: redesign of hotel main gantt menu. ([7f206867](https://github.com/growerp/growerp/commit/7f20686712673b89a7f01fbd7d4674011f592913))
 - **FEAT**: refact: login sequence & added a payment screen at login when not subscribed: first working version with Stripe with debug messages and need for Sripe key in first company creation which is The GrowERP company, receiving subscription payments from tenants. ([0ef0a42f](https://github.com/growerp/growerp/commit/0ef0a42f890a8d3276e1f7e84badc9572909729c))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**: Add MCP Chat functionality and related configurations. ([9e9b45d5](https://github.com/growerp/growerp/commit/9e9b45d5fa807c1d8419cfc4c5f1a8238ebf0e19))
 - **FEAT**: implement local session persistence for API keys and tokens while refining auth error handling. ([2b09618d](https://github.com/growerp/growerp/commit/2b09618d85f8e82232801d5d7b9187f120000dec))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**: added an AIprompt button on all windows, AI apikey can be set at accounting/systemSetup. ([90ecb38f](https://github.com/growerp/growerp/commit/90ecb38fbc85a77ca4012afbb8d6f26bec260f9e))
 - **FEAT**: AI assisted onboarding process, remove email template module, update chat service,. ([828c06d4](https://github.com/growerp/growerp/commit/828c06d4ac47e89e514dd3dc6a9913097c3b17e5))
 - **FEAT**: implement GL account code masking, improve WebSocket connection handling, and refine notification bloc logic. ([284bc3e9](https://github.com/growerp/growerp/commit/284bc3e9f2234dd0ccc38842f6ebf016610511ac))
 - **FEAT**: show debugShowCheckedModeBanner when there is a backendurl override. ([bb21317c](https://github.com/growerp/growerp/commit/bb21317cdd324961926880323f94335c52d2b920))
 - **FEAT**: replace MCP Chat with ADK AI Chat. ([fcf77f5d](https://github.com/growerp/growerp/commit/fcf77f5daec33b45a523a057150f2bc29c909a6f))
 - **FEAT**: show owner REST stats on support owner record, removed RESTAPI listing". ([c3257693](https://github.com/growerp/growerp/commit/c3257693151a29871854a41c0600f09316679ba6))
 - **FEAT**(adk): add AI assistant FAB that opens chat dialog. ([1c65fe1b](https://github.com/growerp/growerp/commit/1c65fe1b297022a6bd2c39fe85fbbc4b84a771fd))
 - **FEAT**(adk): agent config UI, per-agent chat, and menu integration. ([cb717125](https://github.com/growerp/growerp/commit/cb717125a4a893f59e6c4b20e3592740b1ab952f))
 - **FEAT**: implement ADK agent job management and migrate agent config model to shared package. ([7834eebd](https://github.com/growerp/growerp/commit/7834eebdd351dade6929124802edc6f7554b34b0))
 - **FEAT**: implement system settings management AI key, email tool settings. ([f3d6a27d](https://github.com/growerp/growerp/commit/f3d6a27dfcc9408f1e0bf731343ac4d6a8d8f65d))
 - **FEAT**: implement modular LLM provider configuration and migrate existing Gemini API keys. ([53c1256a](https://github.com/growerp/growerp/commit/53c1256a8e54ec9a0ec64dc8cfd1af065587e2de))
 - **FEAT**: add widget registration support to testing framework and update demo list integration tests to use keyed button targets. ([edc87a0c](https://github.com/growerp/growerp/commit/edc87a0c661496edf53d2b1d3d38a2dffaf3572e))
 - **FEAT**: open operational screens from the ADK chat assistant. ([f4533f0b](https://github.com/growerp/growerp/commit/f4533f0b1f8b3ba0a8f738b31d007436c4a87612))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: add path parameter to chatserver. ([b908ce4a](https://github.com/growerp/growerp/commit/b908ce4a73a3e93be792ac4cbfb439581f884d12))
 - **FEAT**: make GitHub repository configurable per tenant via SystemSettings. ([eb069e4e](https://github.com/growerp/growerp/commit/eb069e4ed3c654e0bcb5076a68042c51a530e41f))
 - **FEAT**: instant web startup login/register page (admin + freelance). ([07158550](https://github.com/growerp/growerp/commit/07158550c732c974e0a68b4654af4ff68d6dee2b))
 - **FEAT**: add "Do you need an ERP system?" assessment after login. ([40b89b70](https://github.com/growerp/growerp/commit/40b89b7044e23570f8d23f4f6ebf9f600f370da7))
 - **FEAT**: growerp_adk building block + agent governance UI. ([c17a2b64](https://github.com/growerp/growerp/commit/c17a2b64e9333124475ac200719b08bd5e3d10f7))
 - **FEAT**: prefill create/edit dialogs from chat directive params (Phase 2). ([55b34e90](https://github.com/growerp/growerp/commit/55b34e907a2d25b906674174d1b23382ef76d69d))
 - **FEAT**(adk): Agent Control Center — external MCP servers + bottom-nav icons. ([e6fbf76f](https://github.com/growerp/growerp/commit/e6fbf76f0311579a149db7220c5b5dd270395741))
 - **FEAT**: implement automated website chat responses by integrating agent configuration into chat services and adding toggle functionality in the ADK agent dialog. ([dc41260a](https://github.com/growerp/growerp/commit/dc41260a302311fd2683b3227c76f6b0266d0fcf))
 - **FEAT**: unified ADK Tools & integrations view; slim System Setup to AI/LLM. ([a743edb7](https://github.com/growerp/growerp/commit/a743edb7afc1220187b35990952345c3bc9d0003))
 - **FEAT**: implement LLM system usage tracking, add monthly token limit settings, and expose audit logs via a new dashboard view. ([901e8197](https://github.com/growerp/growerp/commit/901e8197f898b9dc60e6bdfbbb902b3c018b4c30))
 - **FEAT**: onboarding assessment profiles the business, auto-tailors the menu, feeds the agent. ([61fd67d6](https://github.com/growerp/growerp/commit/61fd67d67455e3226eef33e75025988220ac6738))
 - **FEAT**(outreach,menu): restore-menu button, admin send-queue entry, detail/campaign fixes. ([02391165](https://github.com/growerp/growerp/commit/023911659d93b80e515ca4ba7401cb5c225ea860))
 - **FEAT**(subscription): process trial-expiry renewal payment with currency conversion. ([4321eef9](https://github.com/growerp/growerp/commit/4321eef95560d06c51e0b084c8d069ae2557aea8))
 - **FEAT**(admin): compact half-height marketing dashboard tile. ([344a9887](https://github.com/growerp/growerp/commit/344a98873167a2644c5c05a4ccb3f7eae76a24dd))
 - **FEAT**(crm): capture Google Meet bookings + Gemini minutes as CRM activities. ([4f2e4a05](https://github.com/growerp/growerp/commit/4f2e4a052f7978e5521163a8ac38618ed3a86285))
 - **FEAT**(ai): tenant-configurable LLM model + default to flash-lite, add architecture doc. ([56c78df4](https://github.com/growerp/growerp/commit/56c78df419f1ac8f4039eedb5975a9511114d0e3))
 - **FEAT**(adk): move agent demo load from tenant setup to Agent Control screen. ([357899a9](https://github.com/growerp/growerp/commit/357899a9bdf0578d8878763078bac674a6a0551c))
 - **FEAT**(chat): make chat message text selectable. ([f08a143e](https://github.com/growerp/growerp/commit/f08a143ef0be4234ddd4335fb9d961bd4bfc1a5d))
 - **FEAT**(chat): copy/timestamps/origin tagging in support chat, fix website chat contrast and email dedupe. ([c4ff35f4](https://github.com/growerp/growerp/commit/c4ff35f488d64e8ebdbdc4745cb9a5d2a021cc5c))
 - **FEAT**(rental): rental vertical app with cars/equipment demo data. ([90425783](https://github.com/growerp/growerp/commit/9042578306b1de6dbd2c53655c4ea911bc204930))
 - **FEAT**(support): dashboard statistics tiles and REST statistics view. ([1c9cddd2](https://github.com/growerp/growerp/commit/1c9cddd2cc96d4aa3483d35545248bfc3f39eaec))
 - **FEAT**: implement temporary password reset functionality and create password reset tests. ([fecc13bb](https://github.com/growerp/growerp/commit/fecc13bb876a56432073723b8b10eb3619d132bb))

## 1.9.0

 - **REFACTOR**: now chat server can also be used for notification: renaming to WsServer. ([7031a540](https://github.com/growerp/growerp/commit/7031a540755648763a15b0b0b60607d644195a46))
 - **REFACTOR**: move the getting backend url into the core package. ([b8a73f1d](https://github.com/growerp/growerp/commit/b8a73f1d75cabca812bbcf5e720e45619cf8db62))
 - **REFACTOR**: in flutter client rename notification and chat server to client. ([747b76c7](https://github.com/growerp/growerp/commit/747b76c77497fe51f44481f5c2b38a6087c40ad7))
 - **FIX**: request test. ([1b37a5ba](https://github.com/growerp/growerp/commit/1b37a5badff2cf64135ba79954b2cbdba9bfa20b))
 - **FIX**: replace material banner. ([50489165](https://github.com/growerp/growerp/commit/50489165f27bf0292a97d65f38f7e067007ab55a))
 - **FIX**: more automated test corrections. ([fcc64b3f](https://github.com/growerp/growerp/commit/fcc64b3f825dbf378684bfa3e7689dfd2e824f53))
 - **FIX**: now use growerp.com for base url, restore scaffold in home_form. ([92a42c7a](https://github.com/growerp/growerp/commit/92a42c7a5326ba164a2058c0fc283f5f9149056d))
 - **FIX**: glaccount up/download. ([fc790df7](https://github.com/growerp/growerp/commit/fc790df7971f233b232def1e707948777b4c1940))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: room rental and opporunity test. ([5562a7a3](https://github.com/growerp/growerp/commit/5562a7a322bbf31409a21343758613fa4aef630e))
 - **FIX**: flutter now uses java 17, backend still use java 11, see README for detail. ([8039e551](https://github.com/growerp/growerp/commit/8039e551bf240d012e974f2a1b10e64553218724))
 - **FIX**: position of floating buttons on larger than phone screens. ([12382c49](https://github.com/growerp/growerp/commit/12382c499b1f9c42097e055c63058f2959b165ce))
 - **FIX**: reorganized companyuser tests. ([a9f9a805](https://github.com/growerp/growerp/commit/a9f9a8054027db637a05c7782a8de305f67044a3))
 - **FIX**: removed the workflow functionality. ([b3eb7f16](https://github.com/growerp/growerp/commit/b3eb7f1697769a593d20b5d54dab5fb12e4d4b1e))
 - **FIX**: lead tests. ([a9657cbb](https://github.com/growerp/growerp/commit/a9657cbb8889ac0bf592761c962db70c96311ad6))
 - **FIX**: upgraded hotel app to new packages, aded occupied by room type. ([cd929435](https://github.com/growerp/growerp/commit/cd929435cc3a02667c1e02408e0b90f055e4baf3))
 - **FIX**: adjust backend url. ([0f9ce79f](https://github.com/growerp/growerp/commit/0f9ce79ffad38357ee9d24509bc9b802f641b380))
 - **FIX**: user test. ([e411b568](https://github.com/growerp/growerp/commit/e411b56820c81d07d7bdb0b9c3a5c1d72fe2117f))
 - **FIX**: missing version in pubspec. ([8e92e482](https://github.com/growerp/growerp/commit/8e92e482f4451bb811e7425512dba5fb73e592b1))
 - **FIX**: upgraded and fixed the chat function. ([fbe6e2a4](https://github.com/growerp/growerp/commit/fbe6e2a43b2cbf890714e33cf2cb8aa24b0046c9))
 - **FIX**: upgrade file_picker to remove warning message. ([f5d703c1](https://github.com/growerp/growerp/commit/f5d703c19b1a4e19f0cbfac6eca32362ab4411a1))
 - **FIX**: hotel test. ([e2fe8820](https://github.com/growerp/growerp/commit/e2fe8820cb4a3708e7ff2e53efc331099dc702e8))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: register new company. ([c8b2dd0a](https://github.com/growerp/growerp/commit/c8b2dd0aa8f8179e0cadf94ee94d0fe9e8349554))
 - **FIX**: new company registrtion, more info screen. ([684f2728](https://github.com/growerp/growerp/commit/684f272859e766feb157eaa12bfd1d92862f1ee8))
 - **FIX**: upgraded searchdropdown, fixed some integrated tests. ([8b5ecf51](https://github.com/growerp/growerp/commit/8b5ecf51c9312a45f9ef6147ac0cf8c941502d19))
 - **FIX**: company image not showing. ([68b4b9b9](https://github.com/growerp/growerp/commit/68b4b9b91ffd09b189ffee239482f67ba5fef084))
 - **FIX**: show growerp logo at login screen. ([88149c19](https://github.com/growerp/growerp/commit/88149c192c108584fae84889cf62cdff576860d4))
 - **FIX**: login with the return key in the web version. ([bba6424d](https://github.com/growerp/growerp/commit/bba6424d3adadf5e5ee95d0929fb89acf873e0f0))
 - **FIX**: automated integration test for ledger transactions. ([81ef5b62](https://github.com/growerp/growerp/commit/81ef5b6268fa814af41361d6fe95a2a983bc5ae5))
 - **FIX**: automated tests. ([3a37dee7](https://github.com/growerp/growerp/commit/3a37dee74327b0fb9f5265f424cecd92fedf7ac4))
 - **FIX**: ui improvements and dart generall fixes. ([cac1e074](https://github.com/growerp/growerp/commit/cac1e074d41e4881543d0c180d33af63831adbbb))
 - **FIX**: automated integrations tests, last fixes? ([b7222c65](https://github.com/growerp/growerp/commit/b7222c656f0826146a44e104d4014fae47d18311))
 - **FIX**: more test corrections. ([0532d380](https://github.com/growerp/growerp/commit/0532d38024697eeb3d7c127ccf71f08dc26896b1))
 - **FIX**: more integrated test corrections. ([68c1ae8a](https://github.com/growerp/growerp/commit/68c1ae8ae3e5e5ad5fe318064f808e029e4b4ac7))
 - **FIX**: show password clears username, remember username in newuser, forget password. ([6fb9ef22](https://github.com/growerp/growerp/commit/6fb9ef221aab26769df0057fdb3e28d949626788))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: show debugShowCheckedModeBanner when there is a backendurl override. ([8bc9fd0c](https://github.com/growerp/growerp/commit/8bc9fd0c6333bb89a2d6f405a9ef8ccb00cb29d9))
 - **FEAT**: add path parameter to chatserver. ([0622fd34](https://github.com/growerp/growerp/commit/0622fd34bd35ed9107cd47d2b81d486eacdf6342))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.0
* varous model changes

## 1.3.0
* various changes

## 1.2.4
* upgraded models package 1.2.3
* added data conversion framework

## 1.2.3
* upgraded models package 1.2.3
* moved dio build client here.
* fixed reset user password

## 1.2.2
* removed path reference

## 1.2.1
* reset password fixed

## 1.2.0
* models now moved to separate package
* added pretty logging

## 1.1.3
* different apps can now used with a single email
* ui improvements

## 1.1.2
* add platform indicators

## 1.1.1
* add platform indicators

## 1.1.0
* Moved most used blocs into the core: product/asset/category/user/company/inventory
* Now source stored in https://github.com/growerp/growerp/tree/master/flutter/packages/growerp_core

## 1.0.0
* model changes: 
  * company now directly on order
  * added acquireCost to asset
* added localization
* updated to dart 3
* upgrade to material 3 light/dart scheme
* refactor: removed not required material,GestureDetectors 
* add accounting reports

## 0.9.2
* model changes: Item Type add account info
* removed paymentType model now used itemType
* adjust test data related to itemType

## 0.9.0

* now independant of growerp_user_company, own (small) tests

## 0.9.0-dev.1

* Refactoring and UI improvements.
* move user/company in its own ppackage

## 0.8.0-dev.1

* move order and accounting into its own package

## 0.7.0-dev.3

* add missing files for public usage

## 0.7.0-dev.2

* removed warehouse to inventory package

## 0.7.0-dev.1

* moved core package to src dir
* various changes to confirm to dart standards

## 0.6.0-dev.8

* moved website into its own package

## 0.6.0-dev.7

* re-enable example directory
* add available platforms

## 0.6.0-dev.6

* moved code from example into core
* cleaned up example code

## 0.6.0-dev.5

* freezed files not saved

## 0.6.0-dev.1

* Initial release.
