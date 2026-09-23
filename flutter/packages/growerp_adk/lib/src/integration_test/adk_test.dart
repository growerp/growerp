/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../adk_config_service.dart';

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
      bool gone = !await CommonTest.doesExistKey(tester, 'name0');
      for (int attempt = 0; !gone && attempt < 5; attempt++) {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        gone = !await CommonTest.doesExistKey(tester, 'name0');
      }
      expect(gone, isTrue,
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

  // ── Function catalog ──────────────────────────────────────────────────────
  /// Open the catalog picker from Agent Control, confirm it lists a real seed
  /// function (the Operations Team coordinator, always present once
  /// backend/data/GrowerpOperationsTeamData.xml is loaded) grouped under its
  /// team, then close it. Read-only smoke test: the catalog itself is a plain
  /// GET, so this is deterministic and needs no live LLM call.
  static Future<void> openFunctionCatalog(WidgetTester tester) async {
    await selectAgents(tester);
    await CommonTest.tapByKey(tester, 'openFunctionCatalog',
        seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, 'functionCatalogList');
    await CommonTest.checkWidgetKey(tester, 'function_OPS_COORD');
    await CommonTest.tapByKey(tester, 'closeFunctionCatalog');
  }

  /// Whether an agent created by this test could actually reach an LLM: either
  /// this tenant has its own per-provider key (`llmConfigs`, checked the same
  /// way `AdkAgentConfigDialog` does), or the system-wide free allowance
  /// (`systemTokenLimit`/`tokensUsedThisMonth` — the GOOGLE_API_KEY / shared
  /// key every agent can fall back to per AdkGovernanceServices) still has
  /// room. A brand-new test company always has an empty `llmConfigs` — the
  /// system allowance is what actually makes AI usable for it in practice, so
  /// checking `llmConfigs` alone would make this always report "no key" even
  /// with a real key configured system-wide (caught by running this test live
  /// against a backend with GOOGLE_API_KEY set: llmConfigs came back empty,
  /// systemTokenLimit did not). A test that needs a real AI response should
  /// check this first and skip that part when false, so the suite still
  /// passes on a backend/CI run with no key configured at all.
  static Future<bool> hasLlmApiKey(WidgetTester tester) async {
    final svc = await AdkConfigService.create();
    final settings = await svc.systemSettings();
    final ownKey = settings.llmConfigs.any((c) => (c.apiKey ?? '').isNotEmpty);
    final systemLimit = settings.systemTokenLimit ?? 0;
    final systemUsed = settings.tokensUsedThisMonth ?? 0;
    final systemAllowance = systemLimit > 0 && systemUsed < systemLimit;
    return ownKey || systemAllowance;
  }

  /// Open the catalog picker, then "Suggest a function" from inside it, assert
  /// the description field renders. With an AI key configured on this backend,
  /// actually runs the feasibility check and asserts only that SOME outcome
  /// dialog appeared (never on the LLM's wording or which of the three
  /// outcomes it picked — that would make the test flaky against model
  /// output). With no key configured, cancels instead of calling it — same
  /// reasoning as [openChatDialog] not sending a chat message.
  static Future<void> openSuggestFunctionDialog(WidgetTester tester) async {
    await selectAgents(tester);
    await CommonTest.tapByKey(tester, 'openFunctionCatalog',
        seconds: CommonTest.waitTime);
    await CommonTest.tapByKey(tester, 'suggestFunction');
    await CommonTest.checkWidgetKey(tester, 'suggestFunctionDescription');

    if (await hasLlmApiKey(tester)) {
      await CommonTest.enterText(
          tester, 'suggestFunctionDescription', 'summarize open sales orders');
      await CommonTest.tapByKey(tester, 'checkSuggestFunction',
          seconds: CommonTest.waitTime * 3);
      // Exactly one of these three outcome-dismiss keys renders, depending on
      // the model's (non-deterministic) verdict — accept any of them.
      if (await CommonTest.doesExistKey(tester, 'reviewSuggestFeasible')) {
        await CommonTest.tapByKey(tester, 'dismissSuggestFeasible');
        // A "feasible" verdict also opens AdkAgentConfigDialog pre-filled from
        // the draft, regardless of which button dismissed the verdict dialog —
        // close it without saving so it doesn't create a real agent.
        if (await CommonTest.doesExistKey(tester, 'AdkAgentConfigDialog')) {
          await CommonTest.tapByKey(tester, 'AdkAgentConfigCancel');
        }
      } else if (await CommonTest.doesExistKey(tester, 'dismissSuggestOutcome')) {
        await CommonTest.tapByKey(tester, 'dismissSuggestOutcome');
      } else {
        await CommonTest.tapByKey(tester, 'dismissSuggestError');
      }
    } else {
      await CommonTest.tapByKey(tester, 'cancelSuggestFunction');
    }
    await CommonTest.tapByKey(tester, 'closeFunctionCatalog');
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
