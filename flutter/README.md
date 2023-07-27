# This is the flutter section of GrowERP


See the README.md file in the root of this project.

For developers:

Currently this directory is using the packages from pub.dev

However the code of these packages is here.

If you want to change them,  first run the following commands:

```sh
dart pub global activate melos # only one time
melos clean
melos bootstrap # remove references to pub.dev and use local packages
melos build_all # generate data models
melos l10n      # generate language localization files
```

Every package has an example package builtin with integration tests.

you can run all integration tests with:

```sh
melos test_all
```