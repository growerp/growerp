## 1.13.0

 - **REFACTOR**(website): move landing pages and assessments to growerp_website. ([34137ff9](https://github.com/growerp/growerp/commit/34137ff9a3aa840f558a4af6e29676497e791545))
 - **FIX**(academy): register CoursesLocalizations delegate. ([c0586d82](https://github.com/growerp/growerp/commit/c0586d82b5cf0b29ed1f5de9f38cb8df1155a3a0))
 - **FIX**(academy): drop donor l10n.yaml that broke the build. ([65564746](https://github.com/growerp/growerp/commit/65564746b42e86ba565019e259c7f237efb9020c))
 - **FIX**(auth): make the first-login trial sequence work in every app. ([5c4ed9f4](https://github.com/growerp/growerp/commit/5c4ed9f49ee364ced46b62c749e03b3494187234))
 - **FIX**: bump file_picker/package_info_plus off deprecated KGP plugin apply. ([9109e8e5](https://github.com/growerp/growerp/commit/9109e8e5301a9832262f376b8c77da3e3a36e319))
 - **FIX**(core): stop leaking the post-logout authz denial to the user. ([a867dbde](https://github.com/growerp/growerp/commit/a867dbde28b28d6fb4b65d16035ea322d18e5d1f))
 - **FIX**(core): keep startup from ending on a blank screen. ([4bf0c759](https://github.com/growerp/growerp/commit/4bf0c7598c6fd54d6d08f8ed3a1ff2e14fc0d752))
 - **FIX**(accounting): ledger import, posting errors and email sending. ([073b8e15](https://github.com/growerp/growerp/commit/073b8e15251ae26004a7b0d4f13000a68ca7645f))
 - **FEAT**(insurance): growerp_insurance block and insurance app. ([7ca4b3bb](https://github.com/growerp/growerp/commit/7ca4b3bb248e8718d5b5b0b4bfe3bc5f88c424a4))
 - **FEAT**(academy): learner app for taking courses. ([443c6415](https://github.com/growerp/growerp/commit/443c6415dd648b0a20463db8a077e5b6e486e00f))
 - **FEAT**(hr): add HR building block with onboarding, leave and self service. ([1eb3bdd6](https://github.com/growerp/growerp/commit/1eb3bdd6bf7cbb8fb3e02090e69a91c7bd28fc1e))
 - **FEAT**(ai): default Gemini model 3.7-flash, resolved centrally. ([eb8bee43](https://github.com/growerp/growerp/commit/eb8bee432fe973c879326357f1fe0aa876b3746c))
 - **FEAT**(core): optional companyPartyId at startup on every platform. ([c558bdf6](https://github.com/growerp/growerp/commit/c558bdf6fcf87271bf7b1ad2af399572c239b22f))

## 1.12.2

 - **FIX**: replace CC0 file-license headers with Apache-2.0 to match the package LICENSE; add example/README.md for pub.dev.

## 1.12.1

 - **FIX**: relicense under Apache License 2.0, remove insecure link from README, refresh dependencies to address pub.dev score.

## 1.12.0

 - **REFACTOR**: rename classificationId to applicationId everywhere. ([9c23feae](https://github.com/growerp/growerp/commit/9c23feae113511b6dfdafbbe095bdb391bf828bf))
 - **REFACTOR**: move growerp_chat package to core and update core dependencies accordingly. ([ee81f96b](https://github.com/growerp/growerp/commit/ee81f96bbb5be43ef337da616ec1fe8754603a2f))
 - **FIX**: remove border of input fields and reformatting. ([468a1715](https://github.com/growerp/growerp/commit/468a17154f816e37efcc4bcc86a0f34fe1774ebd))
 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([42b57b51](https://github.com/growerp/growerp/commit/42b57b519bd403343cacf19607742b6cf09a667d))
 - **FIX**: growerp install error when already installed is modified. ([e389d61f](https://github.com/growerp/growerp/commit/e389d61f6100d1ff28b29174326168e9d9d41246))
 - **FIX**: conversion adjustments. ([55016ea0](https://github.com/growerp/growerp/commit/55016ea002630525189f589c32052adfccbb7661))
 - **FIX**: conversion changes: close and update period totals by year. ([3bc65040](https://github.com/growerp/growerp/commit/3bc650402a20941c1d16ae0f8791c22c2ce545aa))
 - **FIX**: change conversion quantities and lint error. ([f6f2cf08](https://github.com/growerp/growerp/commit/f6f2cf08948d1a5877d954ccad8597ff078a9f92))
 - **FIX**: dart lint and log warnings. ([4221d8b7](https://github.com/growerp/growerp/commit/4221d8b7e1a7508bf46bfead40f46dff2845d7a7))
 - **FIX**: conversion split closing of documents in parts. ([80a97d7f](https://github.com/growerp/growerp/commit/80a97d7f9a9aa0c7140cf719f0144c8abdb24484))
 - **FIX**: data conversion adjustments. ([204330c5](https://github.com/growerp/growerp/commit/204330c5e9562a285194c04059e3e09d1048c165))
 - **FIX**: the growerp finalize conversion command closing a first period. ([9b2729d2](https://github.com/growerp/growerp/commit/9b2729d2ceb50ddec097988006ab033289b03ea2))
 - **FIX**: remove flutter_hive blocking executing in native dart(conversion). ([43bd4eff](https://github.com/growerp/growerp/commit/43bd4eff104570a5b27d84d99a846e9b2d5152a1))
 - **FEAT**(rental): rental vertical app with cars/equipment demo data. ([90425783](https://github.com/growerp/growerp/commit/9042578306b1de6dbd2c53655c4ea911bc204930))
 - **FEAT**(cli): growerp createApp to scaffold new vertical apps. ([28fca91c](https://github.com/growerp/growerp/commit/28fca91c74c5df6ccc6d2427eabe7ec69172778e))
 - **FEAT**: added dragable and minimizable dashboard tile features. ([ed4e9430](https://github.com/growerp/growerp/commit/ed4e943042e336c0b2d6bd5a28a35751763892cf))
 - **FEAT**: Adopt Flutter workspaces and update package dependencies across various packages. ([08103d59](https://github.com/growerp/growerp/commit/08103d59a23fc7d02cbc636ce244b800ccc53bdc))
 - **FEAT**: make space at the main menu for additional modules. ([99682438](https://github.com/growerp/growerp/commit/99682438c024e9db5ffd96e4a6923c9de9eda58c))
 - **FEAT**: upgrade model and growerp packages to version 1.11.6. ([a58d5ad9](https://github.com/growerp/growerp/commit/a58d5ad960d82b2b741e4674e528893b01910714))
 - **FEAT**: extended the growerp command for create/import/export package, check docs for detail.(PLEASE note Locale, changed to String otherwise could not use in CLI). ([3462be78](https://github.com/growerp/growerp/commit/3462be783d4e2b7553a43a2bf702b451189bd521))
 - **FEAT**: refact: login sequence & added a payment screen at login when not subscribed: first working version with Stripe with debug messages and need for Sripe key in first company creation which is The GrowERP company, receiving subscription payments from tenants. ([0ef0a42f](https://github.com/growerp/growerp/commit/0ef0a42f890a8d3276e1f7e84badc9572909729c))
 - **FEAT**: added year parameter to recalculate#GlAccountOrgSummaries. ([4b748f86](https://github.com/growerp/growerp/commit/4b748f86ecf21879f688b3efae39e66ab7825562))
 - **FEAT**: added conversion selection parameters. ([a0a2436f](https://github.com/growerp/growerp/commit/a0a2436fa826cb8d9c1dcfcb642fcc723e25a61c))
 - **DOCS**: added overal convert procedure, roadmap for next year. ([8d3359af](https://github.com/growerp/growerp/commit/8d3359afdc5815030783b91058c8d3c268801536))

## 1.11.6

 - **FIX**: growerp command pure dart including models package, growerp createPackage improvements and fixes. ([a8b70e1c](https://github.com/growerp/growerp/commit/a8b70e1cfa40a0564e283357e8e703570afd36a3))
 - **FEAT**: upgrade model and growerp packages. ([cb1ac35e](https://github.com/growerp/growerp/commit/cb1ac35e3bdc8683c2853ec96151b0c7ef12763b))
 - **FEAT**: extended the growerp command for create/import/export package, check docs for detail.(PLEASE note Locale, changed to String otherwise could not use in CLI). ([801b3091](https://github.com/growerp/growerp/commit/801b3091ba160857b5e657417f54b6558dd7c304))

## 1.9.0

 - **FIX**: growerp install error when already installed is modified. ([300a4df1](https://github.com/growerp/growerp/commit/300a4df158a9393b9d6d96c1dbfcfd33c27d2057))
 - **FIX**: conversion adjustments. ([6b1d4a4a](https://github.com/growerp/growerp/commit/6b1d4a4ab5b8e275ae569aee3dd230d8e0e98aeb))
 - **FIX**: conversion changes: close and update period totals by year. ([09b66538](https://github.com/growerp/growerp/commit/09b66538f856457105d4b00dadf1c2018cd6f765))
 - **FIX**: change conversion quantities and lint error. ([654d0b6d](https://github.com/growerp/growerp/commit/654d0b6df67d1ccc265153873516da5f61364a64))
 - **FIX**: dart lint and log warnings. ([41eec765](https://github.com/growerp/growerp/commit/41eec765eb5da60a4a0362bbc2be9c649a691bd7))
 - **FIX**: conversion split closing of documents in parts. ([f78f1a10](https://github.com/growerp/growerp/commit/f78f1a102c5853b184fc5d8b1657e419ee401793))
 - **FIX**: data conversion adjustments. ([ace79a56](https://github.com/growerp/growerp/commit/ace79a56390c0ed5bc774b5fa2e5d88162d1c53c))
 - **FIX**: the growerp finalize conversion command closing a first period. ([39f37f23](https://github.com/growerp/growerp/commit/39f37f23aa9adb998035431d2f4d78b4484d45b8))
 - **FIX**: remove flutter_hive blocking executing in native dart(conversion). ([617f8e8a](https://github.com/growerp/growerp/commit/617f8e8a1873d409e91706f1897abc565a046c64))
 - **FEAT**: added year parameter to recalculate#GlAccountOrgSummaries. ([dd9ce08d](https://github.com/growerp/growerp/commit/dd9ce08d2ab19fc80392b78a27d69e26ecd1163c))
 - **FEAT**: added conversion selection parameters. ([e327b43a](https://github.com/growerp/growerp/commit/e327b43afeda96981431cf5610603612c56c2733))
 - **DOCS**: added overal convert procedure, roadmap for next year. ([0413edda](https://github.com/growerp/growerp/commit/0413eddac66a6877a56389079c20df220eaba3b3))

## 1.8.1
Error when installed version modified

## 1.8.0
removed chat server, now included in backend

## 1.6.2
* minor fixes

## 1.6.1
* upgraded models package

## 1.6.0
* extended import sub command
* added finalyze conversion sub command

## 1.3.0
* created a conversion framework

## 1.2.5
* package upgrade

## 1.2.4
* fix stash/pop error with install

## 1.2.3
* fix when no changes to stash
* fix not build when freeze files present

## 1.2.2
* fixed install subcommand
* add ledger transaction import

# 1.2.1
* added optional -url parameter for the backend
* added additional -t parameter for receive timeout
* improve import command with products.

## 1.2.0
- growerp install now working properly
- added conversion example programs
- growerp backend can now be accessed from the terminal.
- Now everything in a single repository.
- upgraded the install , added first version of import and export.

## 0.1.0-dev.10

- upgrade internal packages.

## 0.1.0-dev.9

- aded the packageswitch command to switch between local and pub.dev for all packages.

## 0.1.0-dev.8

- now possible to install specific parts of the system, is used in docker builds

## 0.1.0-dev.7

- added noBuild option for Moqui backend to be used in docker image build

# 0.1.0-dev.6

- added various options to the install command.

## 0.1.0-dev.5

- added the 'growerp switchPackage' command

## 0.1.0-dev.4

- added message when pub.dev limit is reached.

## 0.1.0-dev.3

- fix model files.

## 0.1.0-dev.2

- Created install command.

## 0.1.0-dev.1

- Initial version.
