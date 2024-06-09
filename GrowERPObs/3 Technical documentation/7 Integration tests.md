
# Integration tests

For this system we created integration tests only. We consider unit test too high maintenance. These integration tests are 'kind of' end user readable. The top level integration tests in the admin and hotel etc packages and can be started with the general 'flutter test integration_test/testname_test' command.

if one of the tests fail, you can set the clear parameter to false, and comment out the steps which were already successful executed. Th test will then restart using the data it saved during execution and skip the commented steps.

Initial data is stored in packages/growerp_core/lib/test_data.dart.
When data is created by the tests the resulting ID with the initial data is stored using the 'shared_preferences' package  under the name 'test'. This data can be used in later tests when you need a customer name or created document ID for an order. 

In this test structure is also a sequence variable which is incremented every time an email is created to avoid duplicates which are rejected by the back-end system.  When the test starts a random value is created which id first checked with the back-end if it already exists.

Several challenges exist making the test results consistent. Refreshing the lists and the overlaying of the snackbar message over the floating button key are two examples. Check the testing code how it was solved in this system. 


## The tests are divided into three levels of detail.

Integration tests in GrowERP are organized as a normal program. Code re-use is organized in three levels:
* the lowest level in the growerp_core/common package:
   integration_test/common_test.dart
* The middle level in most packages in the integration_test directories
* The top level in the apps and example directories of the growerp_* packages in the top level integration_test directories

## running the tests

Tests can be started by using the ['Melos'](https://pub.dev/packages/melos) package or manually by going into every package and app and enter the 'flutter test integration_test' from the command line. If you have installed Melos, things get easier by using the 'melos test_package' and 'melos test_app' commands.

## All tests independent.
All tests can be run independently, create their own test data and run in a separate company. When a test is copied from the top /integration_test directory to the lib directory it can be run inside the debugger and single stepped with breakpoints. Within a test, the test can stopped, screens can be modified with hot restart an then the test continued.

All test data is stored in the growerp_core package test_data.dart file.
This test data can be used to initially load, before the test starts or as data to be entered in the screens.

