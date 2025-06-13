## Publishing of packages

remove pubspec overrides with melos clean

- first growerp_models, chat, activities
- then growerp and core package : update version of models
- then other packages: upgrade version of models and core 
- last: admin,freelance, hotel : upgrade versions of all packages

when files removed, need to be deleted in git cache:
git rm --cached <filename>

to publish:
    flutter pub publish
