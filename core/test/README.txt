/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
 
run tests:

just test: 
flutter test

test with coverage:  
flutter test --coverage && genhtml -o coverage coverage/lcov.info && xdg-open coverage/index.html

example tests:
https://github.com/brianegan/flutter_architecture_samples/tree/master/bloc_library/test

complete system:
https://medium.com/flutter-community/flutter-essential-what-you-need-to-know-567ad25dcd8f#47f1

dio test:
https://medium.com/@sahasuthpala/unit-testing-in-dio-dart-package-91b7a78314bc