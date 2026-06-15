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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Reusable integration-test steps for the growerp_adk building block, built to
/// the same pattern as `UserTest` (growerp_user_company): data is carried
/// between steps through [SaveTest] / [PersistFunctions], `add`/`update` take a
/// list while `check`/`delete` are parameterless and read the persisted data.
///
/// All interaction is by widget `Key` only — never by visible text/tooltip —
/// and goes through the shared [CommonTest] helpers. Requires a running backend
/// (port 8080).
class AdkTest {
  // ── AI Agents ─────────────────────────────────────────────────────────────
  static Future<void> selectAgents(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/adk-agents', 'AdkAgentListView');
  }

  static Future<void> addAgents(
    WidgetTester tester,
    List<AdkAgentConfig> agents, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(adkAgentConfigs: agents));
    await enterAgentData(tester);
  }

  static Future<void> updateAgents(
    WidgetTester tester,
    List<AdkAgentConfig> newAgents,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    List<AdkAgentConfig> updated = [];
    for (int i = 0; i < newAgents.length; i++) {
      final oldCfg = old.adkAgentConfigs[i];
      final cfg = newAgents[i].copyWith(adkAgentConfigId: oldCfg.adkAgentConfigId);
      // doNewSearch finds the matching `name0` cell and taps the row, which
      // opens the edit dialog (onRowTap == edit).
      await CommonTest.doNewSearch(tester, searchString: oldCfg.agentName!);
      await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
      expect(CommonTest.getTextField('topHeader').split('#')[1].trim(),
          oldCfg.adkAgentConfigId);
      await _fillAgentForm(tester, cfg);
      await CommonTest.tapByKey(tester, 'AdkAgentConfigSave',
          seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
      await CommonTest.enterText(tester, 'searchField', '');
      updated.add(cfg);
    }
    await PersistFunctions.persistTest(old.copyWith(adkAgentConfigs: updated));
  }

  static Future<void> checkAgents(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final cfg in test.adkAgentConfigs) {
      await CommonTest.doNewSearch(tester, searchString: cfg.agentName!);
      await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
      expect(CommonTest.getTextField('topHeader').split('#')[1].trim(),
          cfg.adkAgentConfigId);
      expect(CommonTest.getTextFormField('agentName'), cfg.agentName);
      if ((cfg.modelName ?? '').isNotEmpty) {
        expect(CommonTest.getTextFormField('modelName'), cfg.modelName);
      }
      if ((cfg.instruction ?? '').isNotEmpty) {
        expect(CommonTest.getTextFormField('instruction'), cfg.instruction);
      }
      if ((cfg.description ?? '').isNotEmpty) {
        expect(CommonTest.getTextFormField('description'), cfg.description);
      }
      expect(CommonTest.getDropdown('toolMode'), cfg.toolMode);
      expect(CommonTest.getDropdown('writePolicy'), cfg.writePolicy);
      if (cfg.toolMode == 'scoped' && (cfg.serviceAllowlist ?? '').isNotEmpty) {
        expect(CommonTest.getTextFormField('serviceAllowlist'),
            cfg.serviceAllowlist);
      }
      await CommonTest.tapByKey(tester, 'cancel');
      await CommonTest.enterText(tester, 'searchField', '');
    }
  }

  static Future<void> deleteAgents(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final cfg in test.adkAgentConfigs) {
      await CommonTest.enterText(tester, 'searchField', cfg.agentName!);
      await CommonTest.checkWidgetKey(tester, 'name0');
      await CommonTest.tapByKey(tester, 'deleteAdkAgent0');
      await CommonTest.tapByKey(tester, 'confirmDeleteAgent',
          seconds: CommonTest.waitTime);
      expect(await CommonTest.doesExistKey(tester, 'name0'), isFalse,
          reason: 'deleted agent "${cfg.agentName}" should no longer be listed');
      await CommonTest.enterText(tester, 'searchField', '');
    }
    await PersistFunctions.persistTest(test.copyWith(adkAgentConfigs: []));
  }

  /// Create each persisted (new) agent via the config dialog, then re-open it to
  /// capture the generated id (from the `topHeader` title) into the saved data.
  static Future<void> enterAgentData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<AdkAgentConfig> newConfigs = [];
    for (final cfg in test.adkAgentConfigs) {
      await CommonTest.tapByKey(tester, 'addAdkAgent');
      await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
      // Trust-foundation controls must be on the form.
      await CommonTest.checkWidgetKey(tester, 'toolMode');
      await CommonTest.checkWidgetKey(tester, 'writePolicy');
      await _fillAgentForm(tester, cfg);
      await CommonTest.tapByKey(tester, 'AdkAgentConfigSave',
          seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
      // Re-open the saved agent to capture its generated id.
      await CommonTest.doNewSearch(tester, searchString: cfg.agentName!);
      await CommonTest.checkWidgetKey(tester, 'AdkAgentConfigDialog');
      final id = CommonTest.getTextField('topHeader').split('#')[1].trim();
      await CommonTest.tapByKey(tester, 'cancel');
      await CommonTest.enterText(tester, 'searchField', '');
      newConfigs.add(cfg.copyWith(adkAgentConfigId: id));
    }
    await PersistFunctions.persistTest(
        test.copyWith(adkAgentConfigs: newConfigs));
  }

  /// Fill the agent config dialog from [a]. Only sets the fields that are
  /// provided so the form's safe defaults stay in place otherwise.
  static Future<void> _fillAgentForm(
    WidgetTester tester,
    AdkAgentConfig a,
  ) async {
    await CommonTest.enterText(tester, 'agentName', a.agentName!);
    if ((a.modelName ?? '').isNotEmpty) {
      await CommonTest.enterText(tester, 'modelName', a.modelName!);
    }
    if ((a.instruction ?? '').isNotEmpty) {
      await CommonTest.enterText(tester, 'instruction', a.instruction!);
    }
    if ((a.description ?? '').isNotEmpty) {
      await CommonTest.enterText(tester, 'description', a.description!);
    }
    final toolLabel = _toolModeLabel(a.toolMode);
    if (toolLabel != null) {
      await CommonTest.enterDropDown(tester, 'toolMode', toolLabel);
    }
    if (a.toolMode == 'scoped' && (a.serviceAllowlist ?? '').isNotEmpty) {
      await CommonTest.checkWidgetKey(tester, 'serviceAllowlist');
      await CommonTest.enterText(tester, 'serviceAllowlist', a.serviceAllowlist!);
    }
    final writeLabel = _writePolicyLabel(a.writePolicy);
    if (writeLabel != null) {
      await CommonTest.enterDropDown(tester, 'writePolicy', writeLabel);
    }
    if (a.scheduleEnabled) {
      // Turning the switch on reveals the schedule fields. The 'scheduleEnabled'
      // key is on the SwitchListTile (not the inner Switch), so detect the
      // current state by whether the schedule field is already shown.
      if (!await CommonTest.doesExistKey(tester, 'scheduleExpression')) {
        await CommonTest.tapByKey(tester, 'scheduleEnabled');
      }
      await CommonTest.enterText(
          tester, 'scheduleExpression', a.scheduleExpression ?? '0 * * * * ?');
      if ((a.schedulePrompt ?? '').isNotEmpty) {
        await CommonTest.enterText(tester, 'schedulePrompt', a.schedulePrompt!);
      }
    }
  }

  static String? _toolModeLabel(String? toolMode) {
    switch (toolMode) {
      case 'readOnly':
        return 'Read-only';
      case 'scoped':
        return 'Scoped (allow-list)';
      case 'full':
        return 'Full';
      default:
        return null;
    }
  }

  static String? _writePolicyLabel(String? writePolicy) {
    switch (writePolicy) {
      case 'block':
        return 'Block writes';
      case 'approve':
        return 'Require approval';
      case 'allow':
        return 'Allow (auto-run)';
      default:
        return null;
    }
  }

  // ── Agent jobs ────────────────────────────────────────────────────────────
  static Future<void> selectJobs(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/adk-jobs', 'AdkJobListView');
  }

  /// Assert each persisted agent has a backing job in the list (a scheduled
  /// agent provisions one).
  static Future<void> checkJobs(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final cfg in test.adkAgentConfigs) {
      await CommonTest.enterText(tester, 'searchField', cfg.agentName!);
      await CommonTest.checkWidgetKey(tester, 'name0');
      expect(CommonTest.getTextField('name0'), cfg.agentName,
          reason: 'a scheduled job for "${cfg.agentName}" should be listed');
    }
    await CommonTest.enterText(tester, 'searchField', '');
  }

  /// Pause then resume the first job in the list (both by key).
  static Future<void> pauseResumeJob(WidgetTester tester) async {
    await CommonTest.checkWidgetKey(tester, 'toggleJob0');
    await CommonTest.tapByKey(tester, 'toggleJob0', seconds: CommonTest.waitTime);
    // After reload the toggle is still present (now showing Resume); tap again
    // to restore the active state.
    await CommonTest.checkWidgetKey(tester, 'toggleJob0');
    await CommonTest.tapByKey(tester, 'toggleJob0', seconds: CommonTest.waitTime);
  }

  // ── Knowledge base ────────────────────────────────────────────────────────
  static Future<void> selectKnowledge(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/adk-knowledge', 'AdkKnowledgeView');
  }

  static Future<void> addKnowledge(
    WidgetTester tester,
    List<AdkKnowledgeDoc> docs,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(adkKnowledgeDocs: docs));
    await enterKnowledgeData(tester);
  }

  static Future<void> enterKnowledgeData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final doc in test.adkKnowledgeDocs) {
      await CommonTest.tapByKey(tester, 'addKnowledge');
      await CommonTest.checkWidgetKey(tester, 'AdkKnowledgeDialog');
      await CommonTest.enterText(tester, 'knowledgeTitle', doc.title!);
      await CommonTest.enterText(tester, 'knowledgeText', doc.content!);
      await CommonTest.tapByKey(tester, 'knowledgeSave',
          seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<void> updateKnowledge(
    WidgetTester tester,
    List<AdkKnowledgeDoc> newDocs,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    for (int i = 0; i < newDocs.length; i++) {
      final oldDoc = old.adkKnowledgeDocs[i];
      // doNewSearch taps the matching row → fetches detail → opens the edit form.
      await CommonTest.doNewSearch(tester, searchString: oldDoc.title!);
      await CommonTest.checkWidgetKey(tester, 'AdkKnowledgeDialog');
      await CommonTest.enterText(tester, 'knowledgeTitle', newDocs[i].title!);
      await CommonTest.enterText(tester, 'knowledgeText', newDocs[i].content!);
      await CommonTest.tapByKey(tester, 'knowledgeSave',
          seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
      await CommonTest.enterText(tester, 'searchField', '');
    }
    await PersistFunctions.persistTest(old.copyWith(adkKnowledgeDocs: newDocs));
  }

  static Future<void> checkKnowledge(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final doc in test.adkKnowledgeDocs) {
      await CommonTest.doNewSearch(tester, searchString: doc.title!);
      await CommonTest.checkWidgetKey(tester, 'AdkKnowledgeDialog');
      expect(CommonTest.getTextFormField('knowledgeTitle'), doc.title);
      expect(CommonTest.getTextFormField('knowledgeText'), doc.content);
      await CommonTest.tapByKey(tester, 'cancel');
      await CommonTest.enterText(tester, 'searchField', '');
    }
  }

  static Future<void> deleteKnowledge(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    for (final doc in test.adkKnowledgeDocs) {
      await CommonTest.enterText(tester, 'searchField', doc.title!);
      await CommonTest.checkWidgetKey(tester, 'title0');
      await CommonTest.tapByKey(tester, 'deleteKnowledge0');
      await CommonTest.tapByKey(tester, 'confirmDeleteKnowledge',
          seconds: CommonTest.waitTime);
      expect(await CommonTest.doesExistKey(tester, 'title0'), isFalse,
          reason: 'deleted knowledge "${doc.title}" should no longer be listed');
      await CommonTest.enterText(tester, 'searchField', '');
    }
    await PersistFunctions.persistTest(test.copyWith(adkKnowledgeDocs: []));
  }

  // ── Approvals (governance) ────────────────────────────────────────────────
  static Future<void> selectApprovals(WidgetTester tester) async {
    await CommonTest.selectOption(
        tester, '/adk-approvals', 'AdkApprovalsListView');
    // The view renders (filter + refresh controls) even with no pending rows.
    await CommonTest.checkWidgetKey(tester, 'refreshApprovals');
  }

  // ── Action audit ──────────────────────────────────────────────────────────
  static Future<void> selectActions(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/adk-actions', 'AdkActionsListView');
    await CommonTest.checkWidgetKey(tester, 'refreshAdkActions');
  }

  // ── AI chat (smoke) ───────────────────────────────────────────────────────
  /// Open the AI-chat dialog via its FAB and assert the composer renders.
  /// (No message is sent — that needs a live LLM and is non-deterministic.)
  static Future<void> openChatDialog(WidgetTester tester) async {
    await CommonTest.gotoMainMenu(tester);
    await CommonTest.tapByKey(tester, 'adkChatFab', seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, 'chatInput');
    await CommonTest.checkWidgetKey(tester, 'chatSend');
    // Close the modal dialog via the popUp close button.
    await CommonTest.tapByKey(tester, 'cancel', seconds: CommonTest.waitTime);
  }

  /// Open the full-screen chat route and assert the composer renders.
  static Future<void> openChatScreen(WidgetTester tester) async {
    await CommonTest.selectOption(tester, '/chat', 'chatInput');
    await CommonTest.checkWidgetKey(tester, 'chatInput');
    await CommonTest.checkWidgetKey(tester, 'chatSend');
  }
}
