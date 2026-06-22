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

/// Tools & integrations screen: the built-in Moqui MCP server shows read-only,
/// Email and GitHub credentials are edited here (relocated from System Setup),
/// and a GitHub save must not clobber the email config (read-modify-write).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('''GrowERP ADK tools & integrations test''', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createAdkExampleRouter(),
      adkMenuConfig,
      UserCompanyLocalizations.localizationsDelegates,
      restClient: restClient,
      blocProviders: getUserCompanyBlocProviders(restClient, 'AppAdmin'),
      title: 'GrowERP ADK tools & integrations test',
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);

    const smtpHost = 'smtp.example.com';
    const mailUser = 'agent@example.com';
    const githubRepo = 'growerp/growerp';

    // ── Tools list shows the built-in tools ──────────────────────────────────
    await CommonTest.selectOption(
        tester, '/adk-mcp-servers', 'AdkMcpServerListView');
    await CommonTest.checkWidgetKey(tester, 'builtinMcpServer');
    await CommonTest.checkWidgetKey(tester, 'emailIntegration');
    await CommonTest.checkWidgetKey(tester, 'githubIntegration');

    // ── Configure Email (SMTP host + SSL security) ───────────────────────────
    await CommonTest.tapByKey(tester, 'configureEmailIntegration');
    await CommonTest.checkWidgetKey(tester, 'EmailSettingsDialog');
    await CommonTest.enterText(tester, 'smtpHost', smtpHost);
    await CommonTest.enterText(tester, 'mailUsername', mailUser);
    await CommonTest.enterText(tester, 'mailPassword', 'secret');
    await CommonTest.enterDropDown(tester, 'smtpSecurity', 'SSL/TLS');
    await CommonTest.tapByKey(tester, 'saveEmailSettings',
        seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);

    // Reopen: email config persisted (host + SSL security).
    await CommonTest.tapByKey(tester, 'configureEmailIntegration');
    await CommonTest.checkWidgetKey(tester, 'EmailSettingsDialog');
    expect(CommonTest.getTextFormField('smtpHost'), smtpHost);
    expect(find.text('SSL/TLS'), findsWidgets,
        reason: 'SMTP security should be persisted as SSL/TLS');
    await CommonTest.tapByKey(tester, 'cancelEmailSettings');

    // ── Configure GitHub (token + repo) ──────────────────────────────────────
    await CommonTest.tapByKey(tester, 'configureGithubIntegration');
    await CommonTest.checkWidgetKey(tester, 'GithubSettingsDialog');
    await CommonTest.enterText(tester, 'githubToken', 'ghp_dummy_token');
    await CommonTest.enterText(tester, 'githubRepository', githubRepo);
    await CommonTest.tapByKey(tester, 'saveGithubSettings',
        seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);

    // ── Anti-clobber: the GitHub save must not reset the email config ─────────
    await CommonTest.tapByKey(tester, 'configureEmailIntegration');
    await CommonTest.checkWidgetKey(tester, 'EmailSettingsDialog');
    expect(CommonTest.getTextFormField('smtpHost'), smtpHost,
        reason: 'GitHub save must not clear the SMTP host');
    expect(find.text('SSL/TLS'), findsWidgets,
        reason: 'GitHub save must not reset SMTP security to default');
    await CommonTest.tapByKey(tester, 'cancelEmailSettings');

    // ── The agent dialog shows the built-in Moqui server (read-only) ─────────
    await AdkTest.selectAgents(tester);
    await CommonTest.tapByKey(tester, 'addAdkAgent');
    await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
    await CommonTest.checkWidgetKey(tester, 'builtinMcpServer');
    await CommonTest.tapByKey(tester, 'AdkAgentConfigCancel');

    await CommonTest.logout(tester);
  });
}
