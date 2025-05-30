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

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/main.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_models/growerp_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  // not implemented yet, use integration_test/chat_test.dart and lib/chatEcho_main.dart
  testWidgets('''GrowERP chat test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(tester, generateRoute, menuOptions,
        CoreLocalizations.localizationsDelegates,
        restClient: restClient,
        clear: true); // use data from previous run, ifnone same as true
    await CommonTest.createCompanyAndAdmin(tester);
    //  await UserTest.selectEmployees(tester);
    //  await UserTest.addAdministrators(tester, [administrators[0]], check: false);
//    await ChatTest.selectChatRoom(tester);
//    await ChatTest.addRooms(tester, chatRooms);
//    await ChatTest.updateRooms(tester);
//    await ChatTest.deleteRooms(tester);
    // needchat echo running
//    await ChatTest.sendDirectMessage(tester);
//    await ChatTest.sendRoomMessage(tester);
  });
}
