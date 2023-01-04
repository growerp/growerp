import 'package:admin/main.dart';
import 'package:growerp_core/api_repository.dart';
import 'package:growerp_core/domains/integration_test.dart';
import 'package:growerp_core/services/chat_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP category test''', (tester) async {
    await CommonTest.startApp(
        tester, TopApp(dbServer: APIRepository(), chatServer: ChatServer()),
        clear: true); // use data from previous run, ifnone same as true
    await CompanyTest.createCompany(tester);
    await CategoryTest.selectCategories(tester);
    await CategoryTest.addCategories(tester, categories);
    await CategoryTest.updateCategories(tester);
    await CategoryTest.deleteLastCategory(tester);
  });
}
