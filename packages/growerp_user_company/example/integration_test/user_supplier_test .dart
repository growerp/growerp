// ignore_for_file: depend_on_referenced_packages
import 'package:user_company_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  Future<void> selectSuppliers(WidgetTester tester) async {
    await UserTest.selectUsers(
        tester, 'dbPersons', 'UserListFormSupplier', '4');
  }

  testWidgets('''GrowERP supplier test''', (tester) async {
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        UserCompanyLocalizations.localizationsDelegates,
        clear: true, title: 'GrowERP user-supplier test');
    await CommonTest.createCompanyAndAdmin(tester);
    await selectSuppliers(tester);
    await UserTest.addSuppliers(tester, suppliers.sublist(0, 2));
    await UserTest.updateSuppliers(tester, suppliers.sublist(2, 4));
    await UserTest.deleteSuppliers(tester);
  });
}
