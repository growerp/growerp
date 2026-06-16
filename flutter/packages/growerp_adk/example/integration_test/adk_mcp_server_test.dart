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

import 'package:adk_example/router_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_adk/src/integration_test/adk_test.dart';

/// External MCP server registry: register, list, edit, attach to an agent,
/// detach, delete. Mirrors the key-driven style of the agent test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK external MCP server test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK external MCP server test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    const serverName = 'Weather MCP';
    const serverUrl = 'http://localhost:8080/mcp/sse';
    const updatedUrl = 'http://localhost:8080/mcp/sse?v=2';

    // ── Register a server ─────────────────────────────────────────────────
    await CommonTest.selectOption(
        tester, '/adk-mcp-servers', 'AdkMcpServerListView');
    await CommonTest.tapByKey(tester, 'addAdkMcpServer');
    await CommonTest.checkWidgetKey(tester, 'AdkMcpServerDialog');
    await CommonTest.enterText(tester, 'serverName', serverName);
    await CommonTest.enterText(tester, 'serverUrl', serverUrl);
    // add one auth header
    await CommonTest.tapByKey(tester, 'addHeader');
    await CommonTest.enterText(tester, 'headerName0', 'Authorization');
    await CommonTest.enterText(tester, 'headerValue0', 'Bearer secret');
    await CommonTest.tapByKey(tester, 'AdkMcpServerSave',
        seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);

    // ── It lists; open and verify fields (header value is write-only) ─────
    await CommonTest.doNewSearch(tester, searchString: serverName);
    await CommonTest.checkWidgetKey(tester, 'AdkMcpServerDialog');
    expect(CommonTest.getTextFormField('serverName'), serverName);
    expect(CommonTest.getTextFormField('serverUrl'), serverUrl);
    final serverId =
        CommonTest.getTextField('topHeader').split('#')[1].trim();
    expect(serverId.isNotEmpty, isTrue);
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.enterText(tester, 'searchField', '');

    // ── Edit the URL ──────────────────────────────────────────────────────
    await CommonTest.doNewSearch(tester, searchString: serverName);
    await CommonTest.enterText(tester, 'serverUrl', updatedUrl);
    await CommonTest.tapByKey(tester, 'AdkMcpServerSave',
        seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.doNewSearch(tester, searchString: serverName);
    expect(CommonTest.getTextFormField('serverUrl'), updatedUrl);
    await CommonTest.tapByKey(tester, 'cancel');
    await CommonTest.enterText(tester, 'searchField', '');

    // ── Attach to an agent, then detach ──────────────────────────────────
    await AdkTest.selectAgents(tester);
    await CommonTest.tapByKey(tester, 'addAdkAgent');
    await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
    await CommonTest.enterText(tester, 'agentName', 'McpHost');
    await CommonTest.tapByKey(tester, 'AdkAgentConfigSave',
        seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    // re-open the saved agent (attach needs an id) and attach the server
    await CommonTest.doNewSearch(tester, searchString: 'McpHost');
    await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
    await CommonTest.tapByKey(tester, 'attachMcpServer');
    await tester.pumpAndSettle();
    await tester.tap(find.text(serverName).last);
    await tester.pumpAndSettle(Duration(seconds: CommonTest.waitTime));
    // the attached server now shows as a tile with a detach button
    await CommonTest.checkWidgetKey(tester, 'mcpServer_$serverId');
    await CommonTest.tapByKey(tester, 'detachMcpServer_$serverId',
        seconds: CommonTest.waitTime);
    expect(await CommonTest.doesExistKey(tester, 'mcpServer_$serverId'), isFalse,
        reason: 'detached server should no longer be listed on the agent');
    await CommonTest.tapByKey(tester, 'AdkAgentConfigCancel');
    await CommonTest.enterText(tester, 'searchField', '');

    // clean up the helper agent
    await CommonTest.enterText(tester, 'searchField', 'McpHost');
    await CommonTest.tapByKey(tester, 'deleteAdkAgent0');
    await CommonTest.tapByKey(tester, 'confirmDeleteAgent',
        seconds: CommonTest.waitTime);
    await CommonTest.enterText(tester, 'searchField', '');

    // ── Delete the server ─────────────────────────────────────────────────
    await CommonTest.selectOption(
        tester, '/adk-mcp-servers', 'AdkMcpServerListView');
    await CommonTest.enterText(tester, 'searchField', serverName);
    await CommonTest.checkWidgetKey(tester, 'name0');
    await CommonTest.tapByKey(tester, 'deleteAdkMcpServer0');
    await CommonTest.tapByKey(tester, 'confirmDeleteServer',
        seconds: CommonTest.waitTime);
    expect(await CommonTest.doesExistKey(tester, 'name0'), isFalse,
        reason: 'deleted MCP server should no longer be listed');

    await CommonTest.logout(tester);
  });
}
