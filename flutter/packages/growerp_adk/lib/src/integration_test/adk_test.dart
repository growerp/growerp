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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

/// Reusable integration-test steps for the growerp_adk building block.
/// Imported by `example/integration_test/adk_test.dart` and by any app that
/// composes growerp_adk. Requires a running backend (port 8080).
class AdkTest {
  // ── AI Agents ─────────────────────────────────────────────────────────────
  static Future<void> selectAgents(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/adk-agents', 'AdkAgentListView');
  }

  /// Open the add-agent dialog, assert the governance controls are present,
  /// create a safe-by-default (read-only) agent and confirm it is listed.
  static Future<void> addReadOnlyAgent(
    WidgetTester tester,
    String agentName,
  ) async {
    await CommonTest.tapByKey(tester, 'addAdkAgent');
    expect(find.byKey(const Key('AdkAgentConfigDialog')), findsOneWidget);

    // Trust-foundation controls must be on the form.
    expect(find.byKey(const Key('toolMode')), findsOneWidget);
    expect(find.byKey(const Key('writePolicy')), findsOneWidget);

    await CommonTest.enterText(tester, 'agentName', agentName);
    // Leave toolMode = readOnly (default) — safe by default.
    await CommonTest.tapByKey(tester, 'AdkAgentConfigSave',
        seconds: CommonTest.waitTime);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('AdkAgentConfigDialog')), findsNothing,
        reason: 'dialog should close after save');
  }

  /// Create a scoped agent whose writes require approval.
  static Future<void> addScopedApprovalAgent(
    WidgetTester tester,
    String agentName,
    String allowlist,
  ) async {
    await CommonTest.tapByKey(tester, 'addAdkAgent');
    expect(find.byKey(const Key('AdkAgentConfigDialog')), findsOneWidget);
    await CommonTest.enterText(tester, 'agentName', agentName);
    await CommonTest.enterDropDown(tester, 'toolMode', 'Scoped (allow-list)');
    // The allow-list field appears once toolMode == scoped.
    expect(find.byKey(const Key('serviceAllowlist')), findsOneWidget);
    await CommonTest.enterText(tester, 'serviceAllowlist', allowlist);
    await CommonTest.enterDropDown(tester, 'writePolicy', 'Require approval');
    await CommonTest.tapByKey(tester, 'AdkAgentConfigSave',
        seconds: CommonTest.waitTime);
    await tester.pumpAndSettle();
  }

  static Future<void> checkAgent(WidgetTester tester, String agentName) async {
    // The list reloads itself after a successful save; just settle and look.
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    expect(find.text(agentName), findsWidgets,
        reason: 'created agent "$agentName" should appear in the list');
  }

  // ── Approvals ───────────────────────────────────────────────────────────--
  static Future<void> selectApprovals(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, '/adk-approvals', 'AdkApprovalsListView');
    // The view renders (filter + refresh controls) even with no pending rows.
    expect(find.byKey(const Key('refreshApprovals')), findsOneWidget);
  }

  // ── Action audit ──────────────────────────────────────────────────────────
  static Future<void> selectActions(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, '/adk-actions', 'AdkActionsListView');
  }
}
