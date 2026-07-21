# GrowERP Wiki

Wiki / OKF knowledge bundle browse and edit module for GrowERP.

Lets you browse and edit the wiki pages that make up the OKF (Open Knowledge Format)
knowledge bundle attached to a company — entity data-model concepts plus hand-authored
notes, organized as a page tree.

Screens:

- `WikiList` — page tree list + page view/edit dialog (`WikiPageDialog`)

## integrated test
An integrated test is available in the example component.
It uses a local backend system, set in: example/assets/cfg/app_settings.json

Start test with melos: (activate with: dart global activate melos)
```sh
melos build_all
melos l10n
cd example
flutter test integration_test
```

## use the example component
Before you can use the Wiki component you have to create a company which sends an email
with a password. Use this password to login and the Wiki component appears in the main
menu.
