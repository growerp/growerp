## 1.11.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers).

## 1.11.0

 - **REFACTOR**: replace `dropdown_search` package with a new custom `AutocompleteLabel` widget. ([48413477](https://github.com/growerp/growerp/commit/48413477e676a04f1de52bab208f77965f3a1cc9))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**(activity): null-safe assignee/thirdParty name display, engagement todo starts in-progress. ([25630015](https://github.com/growerp/growerp/commit/256300154abd2439da7c2aa11fcee27519ba7d6b))
 - **FIX**(ci): increase gradle jvm max heap size to 4g to fix OOM. ([e2f35837](https://github.com/growerp/growerp/commit/e2f3583705c3ca908a53497e04080e57499b79b5))
 - **FIX**: update application ID to com.example.example across example Android build configurations. ([dbf96c32](https://github.com/growerp/growerp/commit/dbf96c32f3d3b60c5ba007ad9d8a9ff8dca89365))
 - **FIX**: resolve Android Gradle compatibility for Glance and update assessment flow navigation logic. ([9afc3720](https://github.com/growerp/growerp/commit/9afc37208ab416a5c2825f18b10f889454e2e3f1))
 - **FIX**: reduce Gradle JVM memory settings and disable the daemon for better resource management. ([265e7c0c](https://github.com/growerp/growerp/commit/265e7c0ca638b959552adcfa4ce2ada3f069ebb3))
 - **FIX**: app bar company not show dialog. ([077c33d0](https://github.com/growerp/growerp/commit/077c33d081a58a3178424b26e9a1c20101902788))
 - **FIX**: Debounce search on all bloc and lists,search on pseudoId,fixed automated tests. ([41d92ecf](https://github.com/growerp/growerp/commit/41d92ecf698821808d095942388b4749dc9cb3b7))
 - **FIX**: core package automated tests. ([9dbf93d2](https://github.com/growerp/growerp/commit/9dbf93d214db70fdbd312340094ca316e8ebb7ca))
 - **FIX**: enhance state management in dialogs and blocs; improve loading behavior and error handling: result of automated tests. ([746c9f1c](https://github.com/growerp/growerp/commit/746c9f1c605c0cf6119c7661de1d5c97108ae245))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: translations inventory. ([fb345e4f](https://github.com/growerp/growerp/commit/fb345e4ff0ffeaf8ef59ef03fc5e7c0f1a55eee2))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: basic tests of order_accounting, activity. ([7dfc0ffc](https://github.com/growerp/growerp/commit/7dfc0ffccea352ba09f1b30f000ce8c52825c12d))
 - **FIX**: ensure consistent output-class formatting in localization files. ([eda194bc](https://github.com/growerp/growerp/commit/eda194bc41bc522506cfba7c9f5e9787237c05b3))
 - **FIX**: standardize on l10n locations. ([91637add](https://github.com/growerp/growerp/commit/91637add065153a611a4d27eb6872a89e6af4a5d))
 - **FIX**: null pointer opportunity & activity. ([bb708f86](https://github.com/growerp/growerp/commit/bb708f86e662dcf6f2bbf9860e412fe7f4cd4268))
 - **FIX**: remove all meta data from non english language files. ([619fb08d](https://github.com/growerp/growerp/commit/619fb08dce611ba4c9867e6a83c1ff9e3a3166fd))
 - **FIX**: for last commit. ([49c7d3d4](https://github.com/growerp/growerp/commit/49c7d3d462a20c90c5a83fafcb87c0b13fa5450c))
 - **FIX**: stripe entity name and remove l10n parameter. ([ae85f7c2](https://github.com/growerp/growerp/commit/ae85f7c21a2cbaa4dfbad10c1854e7ffc29a0647))
 - **FIX**: bloc messages now translated. ([d5a453c2](https://github.com/growerp/growerp/commit/d5a453c2e254501388ccdcc450e12af331d65fe5))
 - **FIX**: update JVM arguments in gradle.properties for improved performance and stability. ([d5b1b327](https://github.com/growerp/growerp/commit/d5b1b327c25fe242d9812e2d0827790d5e18e0e0))
 - **FIX**: all build and lint errors..TODO remained.... ([331ca65a](https://github.com/growerp/growerp/commit/331ca65aa3b66fe18c3853718be610404b55b641))
 - **FIX**: purchase payment test, removed old icons, removed project documents, old menu files". ([7d3e87a1](https://github.com/growerp/growerp/commit/7d3e87a12c771e8a19a00925fe58b56b25854023))
 - **FIX**: remove duplicate hero keys. ([866c4243](https://github.com/growerp/growerp/commit/866c4243fe5513b7983f319233abb939a645f947))
 - **FIX**: translation errors on the main menus corrected. ([7539c887](https://github.com/growerp/growerp/commit/7539c8870d779dd9472055cf3d2330d1fe1fe753))
 - **FIX**: hotel automated tests. ([a988acff](https://github.com/growerp/growerp/commit/a988acffe98905716be6999c02156c1e263717a7))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: implemented a centralwidget registry which is loaded by packages independently to be able to start screenwidget dynamically. ([0fbaa9b5](https://github.com/growerp/growerp/commit/0fbaa9b5b5e32894d2fee1747119abc057e85781))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**: Replace `InputDecorator` with new `GroupingDecorator` for consistent form field styling across various dialogs and screens. ([6501c6a9](https://github.com/growerp/growerp/commit/6501c6a9ab3226471eddb6a2a708ee98d94cd1b8))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**(freelance): time billing for assistants — approval, invoicing, report. ([caaf74e9](https://github.com/growerp/growerp/commit/caaf74e9b98ee7ea0bcef0e374736bdf462ef422))
 - **FEAT**: added the french language. ([95580c3d](https://github.com/growerp/growerp/commit/95580c3de6a4500ed1aa10eff388871786228293))
 - **FEAT**: added the German language. ([56eb0838](https://github.com/growerp/growerp/commit/56eb08381c90db157e44a5be978bc3e3daef82c8))
 - **FEAT**: Add initial Mandarin Chinese language support. ([a0d7f98d](https://github.com/growerp/growerp/commit/a0d7f98df84c5f38e9f7431c1acb08c688276dfe))
 - **FEAT**: deep linking for admin/hotel/support app; see docs/deeplinking.md. ([3fa3aae0](https://github.com/growerp/growerp/commit/3fa3aae0dde4a4329d4226d09ade9b57ceb74846))
 - **FEAT**: Implement HTTP response caching with `dio_cache_interceptor`, configurable cache duration, and cache invalidation on logout and mutating requests. ([adece8f9](https://github.com/growerp/growerp/commit/adece8f919faa3be095382c02ddc2c5621a5f5e7))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: Automated submission to the application stores. ([89d3ac64](https://github.com/growerp/growerp/commit/89d3ac64b54b9cc5dd7877b725e252d8f57807b9))
 - **FEAT**: Add Dutch language support. ([d7ed2b44](https://github.com/growerp/growerp/commit/d7ed2b44d012f12b9a2dddf98ba475b311ff3678))
 - **FEAT**: allow persons with optional company to make reservations. ([081698a0](https://github.com/growerp/growerp/commit/081698a0612575dfe1fa39bf20293f94f5b7c5ba))
 - **FEAT**: activity translations. ([4c0806e2](https://github.com/growerp/growerp/commit/4c0806e230693a81d7a94f594056a99ce066ebed))
 - **FEAT**(l10n): Enhance localization files with descriptions for various fields. ([4e200b40](https://github.com/growerp/growerp/commit/4e200b402a7c02a35c9a867d4f1aaf417c3dc2ed))
 - **FEAT**: Add GrowERP Production Release Tool with comprehensive features. ([4a6cd2cf](https://github.com/growerp/growerp/commit/4a6cd2cf0fda4817e8706247352724bed6ba7f76))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: Extended main menu for Tasks and Freelance dashboard. ([531c9836](https://github.com/growerp/growerp/commit/531c983698823673b7f6b29c5674255b5cdf5b3b))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **DOCS**: actualize app and building-block README files. ([1d0c980a](https://github.com/growerp/growerp/commit/1d0c980a326734bffc3afbe6e000bb38505d2ef9))

## 1.8.1

 - **FIX**: for last commit. ([e78366a1](https://github.com/growerp/growerp/commit/e78366a1404852b8ffec26280474b254aa25299e))

## 1.8.0
* resplace the growerp_task package by adding events
* initial version
