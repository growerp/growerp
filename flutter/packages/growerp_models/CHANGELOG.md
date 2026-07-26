## 1.12.2

 - **FIX**: lengthen pubspec description for pub.dev; drop a redundant `invalid_annotation_target` ignore comment on FinDoc.status.

## 1.12.1

 - **FIX**: relicense under Apache License 2.0 (LICENSE and file headers); add example/main.dart for pub.dev.

## 1.12.0

 - **REFACTOR**: update subscription dialog to dynamically fetch and display product plans from DataFetchBloc. ([fd01461e](https://github.com/growerp/growerp/commit/fd01461e3d2ff0d4247c2fe3f8b765636816f165))
 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: remove internal appointment scheduling system in favor of external solutions. ([eb707d7e](https://github.com/growerp/growerp/commit/eb707d7eba01655bd260c7dc002ffac95843d82d))
 - **REFACTOR**: created html website templates, streamline store pricing UI, add module navigation, and update service definitions, overhaul store footer UI components with modern design and update deployment script references. ([0d7851f8](https://github.com/growerp/growerp/commit/0d7851f81a962fe7d8d14a4e4d725558a341cbca))
 - **REFACTOR**: remove post-login onboarding assistant. ([84741be1](https://github.com/growerp/growerp/commit/84741be13dfbedde801227a864ca42bd51db0356))
 - **REFACTOR**: Remove overloading of apiKey by creating loginStatus for authentication flow. ([d4728e99](https://github.com/growerp/growerp/commit/d4728e99707c6fe13cd3df897188f9f8f24b3009))
 - **FIX**: locale problem caused by 3462be783d4e2b7553a43a2bf702b451189bd521. ([f525736e](https://github.com/growerp/growerp/commit/f525736e6718dc0bce0ea54febc9420891cb5b01))
 - **FIX**: reliably mark app used via dedicated register#AppUsed endpoint. ([f001de42](https://github.com/growerp/growerp/commit/f001de425c030bb5a53e5e29655bac652eff1f61))
 - **FIX**(security): scope get#RestRequest to REST-declared services only. ([9ffd01ef](https://github.com/growerp/growerp/commit/9ffd01efe4318899cef3ec47041a7988c0a75f11))
 - **FIX**: Update outreach messaging and added missing GeneratePlatformMessage in growerp.rest.xml. ([0ee2277d](https://github.com/growerp/growerp/commit/0ee2277db23d52ebf23b0e8ee44c01775aa5866e))
 - **FIX**: update return type of importAdkKnowledgeProducts from Map to dynamic: verify phase 3 Ai native. ([62d8e786](https://github.com/growerp/growerp/commit/62d8e7867097a6b422f73b14415caf36de38ccfc))
 - **FIX**: course and landing page tests. ([927e462f](https://github.com/growerp/growerp/commit/927e462fa6ab187d9026a3aeb8d133cfe45406bb))
 - **FIX**: humanize workeffort status. ([e9020b58](https://github.com/growerp/growerp/commit/e9020b58b04001532b6e2ae274beef35c761096a))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: dynamic menu test. ([9158d362](https://github.com/growerp/growerp/commit/9158d3629c39e77c88641be7b9efa1880b3620ad))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: conversion split closing of documents in parts. ([80a97d7f](https://github.com/growerp/growerp/commit/80a97d7f9a9aa0c7140cf719f0144c8abdb24484))
 - **FIX**: outreach order-accounting website automated tests. ([1f1b70f8](https://github.com/growerp/growerp/commit/1f1b70f8f80ed0b4de71eb74d3fe00912aa1bc36))
 - **FIX**: integrated tests: user_company, sales. ([f22cd5a0](https://github.com/growerp/growerp/commit/f22cd5a04f79ac48e9b60cd784ece24040853d0d))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([f25f7543](https://github.com/growerp/growerp/commit/f25f7543143a65d942a2833f88413d494987d727))
 - **FIX**: basic tests of order_accounting, activity. ([7dfc0ffc](https://github.com/growerp/growerp/commit/7dfc0ffccea352ba09f1b30f000ce8c52825c12d))
 - **FIX**: marketing dates. ([600acf8a](https://github.com/growerp/growerp/commit/600acf8aa09c7ceb3140c44a2e1504225bd4c097))
 - **FIX**: remove flutter_hive blocking executing in native dart(conversion). ([43bd4eff](https://github.com/growerp/growerp/commit/43bd4eff104570a5b27d84d99a846e9b2d5152a1))
 - **FIX**: missing file for previous commit. ([b413f048](https://github.com/growerp/growerp/commit/b413f048d6789688d1b32cb89f7c43a81af6a443))
 - **FIX**: build, retrofit version upgrade. ([151aba22](https://github.com/growerp/growerp/commit/151aba229af93765b60b432564c1d6bef1ecee61))
 - **FIX**: added questions test to assessment. ([6f8a2bb3](https://github.com/growerp/growerp/commit/6f8a2bb39de7aab790d169592d87ac1d998ad831))
 - **FIX**: assessment test succeeded. ([c312b0cc](https://github.com/growerp/growerp/commit/c312b0cc97cf4511ae006ce6421c279bec86550d))
 - **FIX**: landingpage automated test succeeded. ([e8807c4d](https://github.com/growerp/growerp/commit/e8807c4dde1397dddde2178b48980a97cf6eaf42))
 - **FIX**: landing page tested successfull with automated test. ([b800aad3](https://github.com/growerp/growerp/commit/b800aad331769cce5f83ae5ef4a2635c1056f5ee))
 - **FIX**: assignment and landingpage maintenance now hand tested and fixed errors. ([96476ce9](https://github.com/growerp/growerp/commit/96476ce97cebef94fc400e863a5e4705b2642319))
 - **FIX**: verious fixes and started integration test around the landingpage/assessment. ([3f8777c0](https://github.com/growerp/growerp/commit/3f8777c07a281b9ba2de77178d5f1b37b2fdc31f))
 - **FIX**: assessment load on demo data, questions not listed on assessment. ([848ef52e](https://github.com/growerp/growerp/commit/848ef52e38ab8be80a5e7beb4871929c5d5903ae))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([22fd361f](https://github.com/growerp/growerp/commit/22fd361f040ac166bc0030fed151819424fc5343))
 - **FIX**: translations inventory. ([fb345e4f](https://github.com/growerp/growerp/commit/fb345e4ff0ffeaf8ef59ef03fc5e7c0f1a55eee2))
 - **FIX**: improve error handling in getDioError and update SnackBar display in HelperFunctions. ([4d725096](https://github.com/growerp/growerp/commit/4d7250967022985bf935142aecea2e512addaed4))
 - **FIX**: more timezone corrections. ([31b0bb52](https://github.com/growerp/growerp/commit/31b0bb524553b8eee9411e8a9c59d592d210c0c4))
 - **FIX**: subscription test & debugged function. ([eec77aba](https://github.com/growerp/growerp/commit/eec77abaf1f5102dfb078d1a1a334e625b3ea746))
 - **FIX**: check last payment not older than one month, allow one week to pay, improved login sequence, fixed reset password. ([883bc030](https://github.com/growerp/growerp/commit/883bc0301ff5a9fb6ca166bab94b7904638ac11d))
 - **FIX**: prompt for subscription payment improved, only work when stripe API key present for owner 100000=GrowERP irself. ([60ce71ab](https://github.com/growerp/growerp/commit/60ce71ab7d40c76c64701ffd3973480d5aef66ac))
 - **FIX**: various fixes and enhancements of the hotel app. ([5f666f52](https://github.com/growerp/growerp/commit/5f666f527b6dcfd8dbeca40abd91887728a06d32))
 - **FIX**: automated integration tests, solved related problems. ([54cbef9b](https://github.com/growerp/growerp/commit/54cbef9b08d55a930c986c33235107a923bd4d6f))
 - **FIX**: removed the workflow functionality. ([97c9ee60](https://github.com/growerp/growerp/commit/97c9ee606ec1f74fb4a7e3faf804e290ac08c5fd))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([efb3e3c5](https://github.com/growerp/growerp/commit/efb3e3c59a6b70702b2b31f5ac07d57ca0251a58))
 - **FIX**: glaccount up/download. ([1e456a90](https://github.com/growerp/growerp/commit/1e456a90b76d0529f1082d7bda076c2a685ca89d))
 - **FIX**: changes to previous commit: override backend url. ([adefed3c](https://github.com/growerp/growerp/commit/adefed3c6f9ac80d9e8f1de3393a39b8807cfc90))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([93216258](https://github.com/growerp/growerp/commit/932162588cac34b8689ab5eeb8fecb1a2d38153a))
 - **FIX**: reorganized companyuser tests. ([e62c46c0](https://github.com/growerp/growerp/commit/e62c46c0056b40821d239a6bee8b8cc4e1de93b2))
 - **FIX**: corrected login for employees, chat working again. ([a2cd64f9](https://github.com/growerp/growerp/commit/a2cd64f905c94139a3831891660d9a2fadfd32ea))
 - **FIX**: upgraded and fixed the chat function. ([1909eb76](https://github.com/growerp/growerp/commit/1909eb7673ebb3964ebf410d5df5aa17ad31de02))
 - **FIX**: fixes to assesment and landing page, landingpage/checkoutOnePage/admin paths now viewable in website dialog, demo data for landingpage. ([f1ea9f73](https://github.com/growerp/growerp/commit/f1ea9f7395c48f41c61c4414f492724f2b77196c))
 - **FEAT**: knowledge detail/edit + UserList-style list with search. ([b7d6105b](https://github.com/growerp/growerp/commit/b7d6105b641c5e4cc71253cd480d101a9f614194))
 - **FEAT**(marketing): unify landing pages with website forms into one tenant-scoped system. ([d0df630d](https://github.com/growerp/growerp/commit/d0df630d9a39c6762597a7556328292058de5107))
 - **FEAT**(marketing): auto-publish approved content, X publisher, daily limits. ([7a4dcfdd](https://github.com/growerp/growerp/commit/7a4dcfdd2af005eade26b4aba40762eb5cbe0a46))
 - **FEAT**: make GitHub repository configurable per tenant via SystemSettings. ([eb069e4e](https://github.com/growerp/growerp/commit/eb069e4ed3c654e0bcb5076a68042c51a530e41f))
 - **FEAT**: add githubToken to SystemSettings for tenant-scoped GitHub Actions integration. ([cd0e1de9](https://github.com/growerp/growerp/commit/cd0e1de91e6199d6c178eb93702b1f12616fe6f9))
 - **FEAT**: implement modular LLM provider configuration and migrate existing Gemini API keys. ([53c1256a](https://github.com/growerp/growerp/commit/53c1256a8e54ec9a0ec64dc8cfd1af065587e2de))
 - **FEAT**: implement system settings management AI key, email tool settings. ([f3d6a27d](https://github.com/growerp/growerp/commit/f3d6a27dfcc9408f1e0bf731343ac4d6a8d8f65d))
 - **FEAT**: implement ADK agent job management and migrate agent config model to shared package. ([7834eebd](https://github.com/growerp/growerp/commit/7834eebdd351dade6929124802edc6f7554b34b0))
 - **FEAT**: implement temporary password reset functionality and create password reset tests. ([fecc13bb](https://github.com/growerp/growerp/commit/fecc13bb876a56432073723b8b10eb3619d132bb))
 - **FEAT**(chat): copy/timestamps/origin tagging in support chat, fix website chat contrast and email dedupe. ([c4ff35f4](https://github.com/growerp/growerp/commit/c4ff35f488d64e8ebdbdc4745cb9a5d2a021cc5c))
 - **FEAT**: first version of the onboarding assistant. ([bf456ed5](https://github.com/growerp/growerp/commit/bf456ed50efebba1b73029962c64d523a3206584))
 - **FEAT**(agent-control): add dashboard tile matching marketing/outreach pattern. ([e2f8ac09](https://github.com/growerp/growerp/commit/e2f8ac09d07b24a1bccfc600fd3c79c3b0778a38))
 - **FEAT**(manufacturing): add dashboard tile matching marketing/outreach pattern. ([1d71506a](https://github.com/growerp/growerp/commit/1d71506a4859c415f0b48644409a33cad1b3caeb))
 - **FEAT**: add routing to manufactoring. ([31b73c8e](https://github.com/growerp/growerp/commit/31b73c8e03011fcf128077fb0052827bce3e794d))
 - **FEAT**(acct-ledger): add dashboard tile matching marketing/outreach pattern. ([e4dc3ad8](https://github.com/growerp/growerp/commit/e4dc3ad8427fcb43c0d27af73df587094570ec39))
 - **FEAT**: add process demo option, only in test. ([8f3faf3d](https://github.com/growerp/growerp/commit/8f3faf3d253ba6bd8c9af211f49d785aa5cdb85b))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: add email template list to support app. ([ae6c35ae](https://github.com/growerp/growerp/commit/ae6c35aeda0a5f5d0df31ee0622c5e00c03ccd8e))
 - **FEAT**: initial version of the manufacturing package. ([176c610b](https://github.com/growerp/growerp/commit/176c610b7c6180fd9bcc61d45e5dd5bad16a932a))
 - **FEAT**: first version of the Elearner app. ([2179a602](https://github.com/growerp/growerp/commit/2179a6022771871f4616115ee97eb01fdfab229b))
 - **FEAT**: social posting jobs. ([e824ad10](https://github.com/growerp/growerp/commit/e824ad10948150cd5628f1554c9905e5bacbf35b))
 - **FEAT**: prepare for automation on substack and linkedin. ([4bc12197](https://github.com/growerp/growerp/commit/4bc1219774e459ab3c0fbc5a710cbbfbc04d70da))
 - **FEAT**: dynamically load all currencies from the backend and upgrade currency selection fields to use autocomplete. ([10752274](https://github.com/growerp/growerp/commit/10752274141937636720599be06fc670695adf3b))
 - **FEAT**: Display company name in the rest request list and enable searching by user or company name. ([1c7f4175](https://github.com/growerp/growerp/commit/1c7f4175e867545e62424cba2222f21fbe50f59e))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: completing the course package. ([c640531f](https://github.com/growerp/growerp/commit/c640531f8a15970547682f68774622fbc1d4c060))
 - **FEAT**: add course model to growerp_models package. ([fc412fa5](https://github.com/growerp/growerp/commit/fc412fa5efc59737694c3fc473cf586038a23ad6))
 - **FEAT**(acct-sales): add dashboard tile matching marketing/outreach pattern. ([24639269](https://github.com/growerp/growerp/commit/246392692b448ccf4bce7e069ca582b66de15acd))
 - **FEAT**: enhance user registration to support multi-tenant creation and trial flows with dedicated services and UI. ([605d1f47](https://github.com/growerp/growerp/commit/605d1f476cc11f5469487d1de8baeff48748e4b5))
 - **FEAT**: add widget metadata with icons, enable menu item status toggling, and improve theme consistency. ([ef688bda](https://github.com/growerp/growerp/commit/ef688bda41f6e1887fded9ee82155dcf45fcb78a))
 - **FEAT**(acct-purchase): add dashboard tile matching marketing/outreach pattern. ([9f98d27a](https://github.com/growerp/growerp/commit/9f98d27a19a91f6bb2a3d7d8a931042bf5196cab))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: another upgrade to the outreach function. ([f3b07557](https://github.com/growerp/growerp/commit/f3b07557fd4971aceca4f63f8eb3ceab97ab3adc))
 - **FEAT**: added selectable platform dependent actions and messages to the outeach campaign. ([c1eeae8b](https://github.com/growerp/growerp/commit/c1eeae8b1f9f7b543f8922c51b9d5434a363321e))
 - **FEAT**(inventory): add dashboard tile matching marketing/outreach pattern. ([933c86be](https://github.com/growerp/growerp/commit/933c86be0e387e24609c8a60d680aba3c82764d6))
 - **FEAT**(orders): add dashboard tile matching marketing/outreach pattern. ([09cfa740](https://github.com/growerp/growerp/commit/09cfa740f74e2e3269135526275649830871e4d5))
 - **FEAT**(catalog): add dashboard tile matching marketing/outreach pattern. ([0adf88a9](https://github.com/growerp/growerp/commit/0adf88a9d56cce5cc00fcb8cf2ddbe3809400969))
 - **FEAT**(crm): add dashboard tile matching marketing/outreach pattern. ([c103105f](https://github.com/growerp/growerp/commit/c103105feeddd8932cd7a1304c06046ec2d7a4ae))
 - **FEAT**(outreach): add dashboard tile matching marketing pattern. ([ccf5afa4](https://github.com/growerp/growerp/commit/ccf5afa4c5e424c279d12661f54bca9360f432c5))
 - **FEAT**(adk): move agent demo load from tenant setup to Agent Control screen. ([357899a9](https://github.com/growerp/growerp/commit/357899a9bdf0578d8878763078bac674a6a0551c))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([e50fbaa2](https://github.com/growerp/growerp/commit/e50fbaa2bbbd2c700ea586e41cd642feba70b62e))
 - **FEAT**: outreach package complete, however not fully tested. ([a94d231c](https://github.com/growerp/growerp/commit/a94d231c0c80580f05b82ea5275f75ea085b74f3))
 - **FEAT**(ai): tenant-configurable LLM model + default to flash-lite, add architecture doc. ([56c78df4](https://github.com/growerp/growerp/commit/56c78df419f1ac8f4039eedb5975a9511114d0e3))
 - **FEAT**: first version of the outreach package. ([d60675cf](https://github.com/growerp/growerp/commit/d60675cf103b944a7253495911016ef2aaa43f0b))
 - **FEAT**: implement social post  CRUD, AI integration and automated integration test. ([842ac88f](https://github.com/growerp/growerp/commit/842ac88fd34fd30b1e376800e3a4ab08ca7ce1b8))
 - **FEAT**(crm): capture Google Meet bookings + Gemini minutes as CRM activities. ([4f2e4a05](https://github.com/growerp/growerp/commit/4f2e4a052f7978e5521163a8ac38618ed3a86285))
 - **FEAT**(support): dashboard statistics tiles and REST statistics view. ([1c9cddd2](https://github.com/growerp/growerp/commit/1c9cddd2cc96d4aa3483d35545248bfc3f39eaec))
 - **FEAT**(wiki): growerp_wiki building block - browse/edit OKF bundle. ([68920b17](https://github.com/growerp/growerp/commit/68920b1758e118ed5d55386dbb0c15dcd9d90822))
 - **FEAT**: creditcard payment only requested after evaluation period. ([9d7f1c0c](https://github.com/growerp/growerp/commit/9d7f1c0c64b4af667509745a0cf005df8758e58d))
 - **FEAT**(marketing): social engagement monitor. ([380ff788](https://github.com/growerp/growerp/commit/380ff78811d42dce2ad72408492926f0fa9b2e39))
 - **FEAT**(marketing): appointment slots + public booking page. ([48dfdf83](https://github.com/growerp/growerp/commit/48dfdf83e8f9e74b872d6ba08a35650becbd021e))
 - **FEAT**(marketing): marketing/sales dashboard. ([332d6943](https://github.com/growerp/growerp/commit/332d69438a74e314957bd40550261c744b88467b))
 - **FEAT**(adk): tenant-enable marketing agent team. ([08677fc5](https://github.com/growerp/growerp/commit/08677fc546ab357a538a076d9216bd371cbf4c66))
 - **FEAT**(marketing): native email nurture-sequence engine. ([8873b927](https://github.com/growerp/growerp/commit/8873b9279ca0fb7cba2ee7a7883df447e3cc64bf))
 - **FEAT**(website): per-page SEO metadata + lead-capture form builder. ([be69deec](https://github.com/growerp/growerp/commit/be69deecec284c90d60d2f37f1d7bf7c56a3a87f))
 - **FEAT**: improved list of landingpage and assessment, added assessment results. ([534031d7](https://github.com/growerp/growerp/commit/534031d754ba95ed15af51123984ebb7dcb7a05d))
 - **FEAT**(sales): pipeline board, funnel report, nextStep auto-activity. ([ed1f5c7a](https://github.com/growerp/growerp/commit/ed1f5c7ab021a6efe7f9491c42e1d1d7c042155e))
 - **FEAT**: AI can now generate a landing page from user supplied company description. ([ad7dc771](https://github.com/growerp/growerp/commit/ad7dc771fd76882104868b01183b421ffb1b9546))
 - **FEAT**: add first version of assessment and landing page tests. ([25a82fab](https://github.com/growerp/growerp/commit/25a82fab5ad8e97bca77d5d4384f6ec470890250))
 - **FEAT**: added landingpage and assessment maintenance screens, viewable in admin/crm. ([82597cb0](https://github.com/growerp/growerp/commit/82597cb0610a8b3a537ad0231e284240bd4d6a5e))
 - **FEAT**(rental): rental vertical app with cars/equipment demo data. ([90425783](https://github.com/growerp/growerp/commit/9042578306b1de6dbd2c53655c4ea911bc204930))
 - **FEAT**: first version of the assesment package. ([c57ae654](https://github.com/growerp/growerp/commit/c57ae6541cb41dcedb1e15a0eb780a55b31137cd))
 - **FEAT**: added invoice upload screens in purchase invoices (gemini link not yet working). ([d1513392](https://github.com/growerp/growerp/commit/d1513392beeff600a25843412b603a5ebabbbe3d))
 - **FEAT**: add support for custom HTML home page templates and hide login links for internal GrowERP stores. ([794fe4b3](https://github.com/growerp/growerp/commit/794fe4b3b180875fa5760a2d6c86d3787d800138))
 - **FEAT**: Add OwnerPersonRestRequest entity and REST API for fetching related data. ([f28e54f3](https://github.com/growerp/growerp/commit/f28e54f3a5e70a09c3b5cd3ba71454b14d284a36))
 - **FEAT**: modernize benefits page with new Bento-style UI and integrate into GrowERP website seed data. ([f46dbc86](https://github.com/growerp/growerp/commit/f46dbc86bc702ecd538232b92887a3445767b38a))
 - **FEAT**: added original payment amount and currency, fixed change radio to switch button on Transaction(flutter -> 3.55). ([42cb43c7](https://github.com/growerp/growerp/commit/42cb43c74269521f502891a6de7be6b94a6ecdfe))
 - **FEAT**(freelance): time billing for assistants — approval, invoicing, report. ([caaf74e9](https://github.com/growerp/growerp/commit/caaf74e9b98ee7ea0bcef0e374736bdf462ef422))
 - **FEAT**(hotel): seasonal rates, web booking, housekeeping, occupancy reports. ([5401b59a](https://github.com/growerp/growerp/commit/5401b59a4e170470503bc8819f3a96d5a968ed1c))
 - **FEAT**: add unit of measure and amount to the product definition, restructuring and fixing product test. ([c2623bf4](https://github.com/growerp/growerp/commit/c2623bf416e98f34a166397bf5234801ba1dda6f))
 - **FEAT**: extend the subscriptions and show current growerp plan in accounting setup. ([cb99d898](https://github.com/growerp/growerp/commit/cb99d898a43245f3204a37496e3a64d37924842e))
 - **FEAT**: extending subscriptions. ([7da11335](https://github.com/growerp/growerp/commit/7da1133528328a90291988ad60c650f9d34d991d))
 - **FEAT**: VERY first version of subscriptions. ([2ca41795](https://github.com/growerp/growerp/commit/2ca41795b4de9181cded554d91a30bcc8779edc9))
 - **FEAT**: added a credit card capture for a trial period, updated tests. ([f6b2123b](https://github.com/growerp/growerp/commit/f6b2123b672407300bb3207a3955f64c16310473))
 - **FEAT**: implement selectable modern tailwind templates for websites. ([165888ff](https://github.com/growerp/growerp/commit/165888ff0ea578a3bad7d0b3909d4274af69804e))
 - **FEAT**(marketing): author-once MasterContent, adapt to 6 platforms. ([21572564](https://github.com/growerp/growerp/commit/21572564175dfb1db77873c9c5459f5deac563b7))
 - **FEAT**: refact: login sequence & added a payment screen at login when not subscribed: first working version with Stripe with debug messages and need for Sripe key in first company creation which is The GrowERP company, receiving subscription payments from tenants. ([0ef0a42f](https://github.com/growerp/growerp/commit/0ef0a42f890a8d3276e1f7e84badc9572909729c))
 - **FEAT**(outreach): async LinkedIn lead import with job title + completion notification. ([00761e7e](https://github.com/growerp/growerp/commit/00761e7e0f8f486bbe422315ba00261981fb0795))
 - **FEAT**: implement LLM system usage tracking, add monthly token limit settings, and expose audit logs via a new dashboard view. ([901e8197](https://github.com/growerp/growerp/commit/901e8197f898b9dc60e6bdfbbb902b3c018b4c30))
 - **FEAT**: implement automated website chat responses by integrating agent configuration into chat services and adding toggle functionality in the ADK agent dialog. ([dc41260a](https://github.com/growerp/growerp/commit/dc41260a302311fd2683b3227c76f6b0266d0fcf))
 - **FEAT**(adk): Agent Control Center — external MCP servers + bottom-nav icons. ([e6fbf76f](https://github.com/growerp/growerp/commit/e6fbf76f0311579a149db7220c5b5dd270395741))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([cc48d8fe](https://github.com/growerp/growerp/commit/cc48d8fe4144b55c23f6f3633537d612e595e286))
 - **FEAT**: wire ADK list screens to backend search (server-side). ([8fb49868](https://github.com/growerp/growerp/commit/8fb4986886fd0880565d209613a2f33473a8155f))
 - **FEAT**: Phase 4a multi-agent orchestration UI + REST route. ([8c654ad5](https://github.com/growerp/growerp/commit/8c654ad545c0856e437933948d79ae91463ab0b6))
 - **FEAT**: added the revenue/expense line chart. ([7e9e37db](https://github.com/growerp/growerp/commit/7e9e37dbd854570c24607987ee103821c4107c8f))
 - **FEAT**: knowledge upload + product-import UI; product-import REST route. ([7b4fbbed](https://github.com/growerp/growerp/commit/7b4fbbed1c9cc9df807111b70efb3278f4179b06))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([55d53999](https://github.com/growerp/growerp/commit/55d539998dc7127720afa6ac5ec4710d3ae9895c))
 - **FEAT**(hotel): housekeeping follows the stay. ([0ad2a931](https://github.com/growerp/growerp/commit/0ad2a931235e750d6f0b3b8588dda50625c12e86))
 - **FEAT**: Phase 3 RAG REST + Knowledge UI + agents menu. ([79e0ff4f](https://github.com/growerp/growerp/commit/79e0ff4f66f7071dc573059433156ed25704a343))
 - **FEAT**: use your own payment processor. ([05b4abdd](https://github.com/growerp/growerp/commit/05b4abdd8e7bba453009da81ef67cb6e6ddd7979))
 - **FEAT**: implement Application entity and migrate mobile app version/url management from PartyClassification to Application service. ([92ac9f19](https://github.com/growerp/growerp/commit/92ac9f19026da2b6843a48257630a462b8632c20))
 - **FEAT**: growerp_adk building block + agent governance UI. ([c17a2b64](https://github.com/growerp/growerp/commit/c17a2b64e9333124475ac200719b08bd5e3d10f7))
 - **FEAT**: implement marketing persona, content plan  CRUD, AI tegration and automated integration test. ([ec4cec20](https://github.com/growerp/growerp/commit/ec4cec20d06a40a053c73c7f0a62b527f60dd1f9))
 - **DOCS**: actualize app and building-block README files. ([1d0c980a](https://github.com/growerp/growerp/commit/1d0c980a326734bffc3afbe6e000bb38505d2ef9))

## 1.11.6

 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([a8b70e1c](https://github.com/growerp/growerp/commit/a8b70e1cfa40a0564e283357e8e703570afd36a3))
 - **FIX**: locale problem caused by 801b3091ba160857b5e657417f54b6558dd7c304. ([6e827925](https://github.com/growerp/growerp/commit/6e82792537431c571ccd62cf0b12e35a62ce03ea))
 - **FIX**: outreach order-accounting website automated tests. ([d278116e](https://github.com/growerp/growerp/commit/d278116e1f8c12350d5663dfdb7ca2d950e247d9))
 - **FIX**: integrated tests: user_company, sales. ([97afe3ce](https://github.com/growerp/growerp/commit/97afe3cea558031bba8bf6b566a173f86542e496))
 - **FIX**: integration test: inventory, orderaccounting, added automated widget key. ([9ec6c7b2](https://github.com/growerp/growerp/commit/9ec6c7b240b47843f172cac4b856cf950eac100d))
 - **FIX**: basic tests of order_accounting, activity. ([66219181](https://github.com/growerp/growerp/commit/66219181fb292490fd24a348eb8f9b9f0933df4e))
 - **FIX**: marketing dates. ([61c494cc](https://github.com/growerp/growerp/commit/61c494cc9dd9a077b5ec2acacac714a89c1a6364))
 - **FIX**: missing file for previous commit. ([945fbcba](https://github.com/growerp/growerp/commit/945fbcba044012e19e4ffd30671ebad02c3ce2cd))
 - **FIX**: build, retrofit version upgrade. ([f6d9dfd1](https://github.com/growerp/growerp/commit/f6d9dfd1956088740fe35b93caf7d84c8a870410))
 - **FIX**: added questions test to assessment. ([5ec1b5a8](https://github.com/growerp/growerp/commit/5ec1b5a8e630e9687fd3c989e4c34b790bbb7cb8))
 - **FIX**: assessment test succeeded. ([b1abef8f](https://github.com/growerp/growerp/commit/b1abef8fc6abcd0fd4b68c532d594c61f48f6592))
 - **FIX**: landingpage automated test succeeded. ([471244a8](https://github.com/growerp/growerp/commit/471244a8db0ee00aeb8ecacb5c6d1c2f8525a163))
 - **FIX**: landing page tested successfull with automated test. ([bfb4e0c4](https://github.com/growerp/growerp/commit/bfb4e0c46ccec6f1984390feeb4499757c68e1d5))
 - **FIX**: assignment and landingpage maintenance now hand tested and fixed errors. ([061f28f1](https://github.com/growerp/growerp/commit/061f28f1fd94eb1c0629e5c81b22063ccc95d906))
 - **FIX**: verious fixes and started integration test around the landingpage/assessment. ([a97b3527](https://github.com/growerp/growerp/commit/a97b3527168e4cab1b4a716d9bd14f94fd802376))
 - **FIX**: assessment load on demo data, questions not listed on assessment. ([3fa0de8b](https://github.com/growerp/growerp/commit/3fa0de8baa6c966686d5f6cc196f6ee250756793))
 - **FIX**: fixes to assesment and landing page, landingpage/checkoutOnePage/admin paths now viewable in website dialog, demo data for landingpage. ([973d9a97](https://github.com/growerp/growerp/commit/973d9a974e84d33b3fde93e55c29f9c89366e37e))
 - **FEAT**: upgrade growerp and model package. ([898d165a](https://github.com/growerp/growerp/commit/898d165ad21333be3c51d0bb559f114d34ae6eed))
 - **FEAT**: another upgrade to the outreach function. ([39589cc1](https://github.com/growerp/growerp/commit/39589cc196e3b479f8e9bc66cf49b91a34a02954))
 - **FEAT**: added selectable platform dependent actions and messages to the outeach campaign. ([b5e428ab](https://github.com/growerp/growerp/commit/b5e428abcf901e198ce5b32954b85c41c9e76a79))
 - **FEAT**: introduced dynamic menus, replaced standerd router with go-router. ([827cdeab](https://github.com/growerp/growerp/commit/827cdeab2f51b7397860d8838efcfce66a15286b))
 - **FEAT**: outreach package complete, however not fully tested. ([eb7af25d](https://github.com/growerp/growerp/commit/eb7af25d2a7754e4a654f5e690a789f2866d63e2))
 - **FEAT**: first version of the outreach package. ([964a63d8](https://github.com/growerp/growerp/commit/964a63d8ec92e054c1b78d07099fe9b5149c9059))
 - **FEAT**: implement social post  CRUD, AI integration and automated integration test. ([b16720e0](https://github.com/growerp/growerp/commit/b16720e0efd413505a90a62b6bdb9206db5b506d))
 - **FEAT**: implement marketing persona, content plan  CRUD, AI tegration and automated integration test. ([ab78d899](https://github.com/growerp/growerp/commit/ab78d899d094fc5bbeef8204b112fa242cba8946))
 - **FEAT**: creditcard payment only requested after evaluation period. ([f221ef54](https://github.com/growerp/growerp/commit/f221ef5446ceb0b2a7644a2d98d224072a3801e7))
 - **FEAT**: improved list of landingpage and assessment, added assessment results. ([0b8646a2](https://github.com/growerp/growerp/commit/0b8646a2f784d228c3e146b3ee54a390c03e783a))
 - **FEAT**: AI can now generate a landing page from user supplied company description. ([da899ed3](https://github.com/growerp/growerp/commit/da899ed34d088ed39a3392a29e01de64930532e7))
 - **FEAT**: add first version of assessment and landing page tests. ([51cd3e4d](https://github.com/growerp/growerp/commit/51cd3e4dcc5a2460e38031897c7553873ed27abc))
 - **FEAT**: added landingpage and assessment maintenance screens, viewable in admin/crm. ([98bc97b7](https://github.com/growerp/growerp/commit/98bc97b7752cf817deb1802c1e319bbab0cfd365))
 - **FEAT**: first version of the assesment package. ([79ee3f05](https://github.com/growerp/growerp/commit/79ee3f05abda4754611c82651512538c0e11fd10))

## 1.9.0

 - **FIX**: removed the workflow functionality. ([b3eb7f16](https://github.com/growerp/growerp/commit/b3eb7f1697769a593d20b5d54dab5fb12e4d4b1e))
 - **FIX**: open session not remembered: replace Hive with shared_references in flutter. ([ae226865](https://github.com/growerp/growerp/commit/ae226865ecb2da59f6a45cf8eb0a22c219921710))
 - **FIX**: glaccount up/download. ([fc790df7](https://github.com/growerp/growerp/commit/fc790df7971f233b232def1e707948777b4c1940))
 - **FIX**: changes to previous commit: override backend url. ([ed7b84b6](https://github.com/growerp/growerp/commit/ed7b84b63cb2b8689bf3d472c5b06f1ea848b359))
 - **FIX**: force refresh on initial display list, change first/lastname order on combined company/user model. ([bf58df13](https://github.com/growerp/growerp/commit/bf58df13e5bf8e32d8001a9554ab45c9d6080951))
 - **FIX**: reorganized companyuser tests. ([a9f9a805](https://github.com/growerp/growerp/commit/a9f9a8054027db637a05c7782a8de305f67044a3))
 - **FIX**: corrected login for employees, chat working again. ([87f41e77](https://github.com/growerp/growerp/commit/87f41e7797ca0a2af5b03305c6b0cc4e004f8598))
 - **FIX**: upgraded and fixed the chat function. ([fbe6e2a4](https://github.com/growerp/growerp/commit/fbe6e2a43b2cbf890714e33cf2cb8aa24b0046c9))
 - **FIX**: upgrade to flutter 3.27, postgres 17.2, removed unmaintained e-commerce package. ([1a9f1f17](https://github.com/growerp/growerp/commit/1a9f1f17928d5e35156ff744338dbb941dfb7222))
 - **FIX**: conversion split closing of documents in parts. ([f78f1a10](https://github.com/growerp/growerp/commit/f78f1a102c5853b184fc5d8b1657e419ee401793))
 - **FIX**: remove flutter_hive blocking executing in native dart(conversion). ([617f8e8a](https://github.com/growerp/growerp/commit/617f8e8a1873d409e91706f1897abc565a046c64))
 - **FEAT**: first version of the company/user upload in company/user list screen. ([36d8a9ea](https://github.com/growerp/growerp/commit/36d8a9eae858751911af57f955cd66d670633d3d))
 - **FEAT**: first version of backend notification, merged with the backend chat. ([e8e75781](https://github.com/growerp/growerp/commit/e8e7578199b7bcf12d5021e90a9d37b26aa9f8b8))
 - **FEAT**: use your own payment processor. ([6ad4e073](https://github.com/growerp/growerp/commit/6ad4e0732d29adf80cfcb6ccc6e7089afb703144))
 - **FEAT**: added the revenue/expense line chart. ([dfba6a09](https://github.com/growerp/growerp/commit/dfba6a09d066600e5e853a8c31a5a3d8e42c5dbf))

## 1.8.0
* Various changes see https://github.com/growerp/growerp/releases

## 1.6.2
* conversion updates
* accounting reports

## 1.6.1
* remove flutter_hive blocking execution in native dart

## 1.6.0
* various model changes

## 1.3.0
* various model changes

## 1.2.4
* various model changes

## 1.2.3
* added more models

## 1.2.2
* added fields for data conversion
* moved dioclient to either growerp or core package

## 1.2.1
* reset password fixed
* product conversion changes

## 1.2.0
* Now centrally all models for flutter and terminal.


