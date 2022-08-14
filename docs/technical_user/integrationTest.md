# Integration tests

For this system we created integration tests only. We consider unit test too high maintenance. These integration tests are 'kind of' end user readable. The top level integration tests in the admin and hotel etc packages and can be started with the general 'flutter test integration_test/growerpTest' command.

If you cloned the growerp from git, it is required to run the freezed build process in core and setup the backend before you can run the test.

if one of the tests fail, you can copy the test file inside the lib directory and test from there using the debugging facility in your favorite IDE. you can also use the hot-restart function there to speed up the testing which is not available in the integration_test directory.


Initial data is stored in [data.dart](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/common/integration_test/data.dart) When data is created by the tests the resulting ID with the initial data is stored using the 'shared_preferences' package via the [persist_functions.dart](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/common/functions/persist_functions.dart) file under the name 'test'. This data can be used in later tests when you need a customer name for an order. 

In this [test structure](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/common/models/save_test_model.dart) is a sequence variable which is incremented every time an email is created to avoid duplicates which are rejected by the backend system.  In order to avoid email duplicated make sure to add android:restoreAnyVersion="true" to the android manifest so the sequence number is not reset when re-running your test. 

Several challenges exist making the test results consistent. Refreshing the lists and the overlaying of the snackbar message over the floating button key are two examples. Check the testing code how it was solved in this system. 


## The tests are divided into three levels of detail.
To promote re-usage of test snippets we have three levels of tests.

### Example test top level
The top level integration tests are stored in the top level packages because menu structure can be different for every top level app like 'admin', 'hotel' etc.  
Test file example fragment from the admin package: admin/integration_test/growerp_test.dart

[filename](https://raw.githubusercontent.com/growerp/growerp/master/packages/admin/integration_test/company_test.dart ':include :type=code :fragment=createCompany')

Full file: [growerp_test.dart](https://raw.githubusercontent.com/growerp/growerp/master/packages/admin/integration_test/growerp_test.dart)

### Example test intermediate level.
the intermediate level tests are stored in the packages/core/lib/domain directories. This level will store the immediate results in shared preferences and will increment the sequence(seq) variable to avoid duplicated email addresses.  
Test file example fragment:

[filename](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/users/integration_test/companyTest.dart ':include :type=code :fragment=newCompany')

Full file: [companyTest.dart](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/users/integration_test/companyTest.dart)

### Example lowest level.
The lowest level is in the common domain in the core package.

[filename](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/common/integration_test/commonTest.dart ':include :type=code :fragment=lowLevel')

Full file: [commonTest.dart](https://raw.githubusercontent.com/growerp/growerp/master/packages/core/lib/domains/common/integration_test/commonTest.dart)
