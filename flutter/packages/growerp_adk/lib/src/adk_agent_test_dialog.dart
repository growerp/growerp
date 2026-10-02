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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

import 'adk_config_service.dart';

/// Test a saved agent: rule checks without AI, then one run with a prompt.
/// With "Simulate writes" on, writes are checked by the governance gate but
/// not executed; the dialog shows every tool call with its decision.
class AdkAgentTestDialog extends StatefulWidget {
  final AdkAgentConfig agent;
  const AdkAgentTestDialog({super.key, required this.agent});

  @override
  State<AdkAgentTestDialog> createState() => _AdkAgentTestDialogState();
}

class _AdkAgentTestDialogState extends State<AdkAgentTestDialog> {
  final _promptCtrl = TextEditingController();
  bool _dryRun = true;
  bool _busy = false;
  List<AdkAgentCheckIssue>? _issues;
  AdkAgentTestRun? _run;
  String? _failure;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _promptCtrl.text = widget.agent.schedulePrompt ?? '';
  }

  @override
  void dispose() {
    _poll?.cancel();
    _promptCtrl.dispose();
    super.dispose();
  }

  String get _configId => widget.agent.adkAgentConfigId!;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _failure = null;
      _run = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final issues = await svc.check(_configId);
      if (mounted) setState(() => _issues = issues);
    } catch (e) {
      if (mounted) setState(() => _failure = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _failure = null;
      _run = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final start = await svc.startTest(_configId,
          prompt: _promptCtrl.text.trim(), dryRun: _dryRun);
      if (!mounted) return;
      setState(() => _issues = start.issues);
      if (start.testRunId == null) {
        setState(() => _busy = false);
        return;
      }
      _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final run = await svc.testRun(start.testRunId!);
          if (!mounted) return;
          setState(() => _run = run);
          if (!run.isRunning) {
            _poll?.cancel();
            setState(() => _busy = false);
          }
        } catch (e) {
          _poll?.cancel();
          if (mounted) {
            setState(() {
              _failure = e.toString();
              _busy = false;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _failure = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return Dialog(
      key: const Key('AdkAgentTestDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: l.adk_testAgentTitle(widget.agent.agentName ?? _configId),
        width: 600,
        height: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('testPrompt'),
              controller: _promptCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.adk_testPrompt,
                helperText: l.adk_testPromptHint,
              ),
            ),
            SwitchListTile(
              key: const Key('testDryRun'),
              contentPadding: EdgeInsets.zero,
              value: _dryRun,
              title: Text(l.adk_testSimulateWrites),
              subtitle: Text(
                _dryRun ? l.adk_testSimulateOn : l.adk_testSimulateOff,
                style: TextStyle(
                    fontSize: 12, color: _dryRun ? Colors.grey : Colors.red),
              ),
              onChanged: _busy ? null : (v) => setState(() => _dryRun = v),
            ),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('testCheck'),
                  onPressed: _busy ? null : _check,
                  child: Text(l.adk_testCheckOnly),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('testRun'),
                  onPressed: _busy ? null : _start,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(l.adk_testRun),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(child: SingleChildScrollView(child: _results(l))),
          ],
        ),
      ),
    );
  }

  Widget _results(AdkLocalizations l) {
    final run = _run;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_failure != null)
          Text(_failure!,
              key: const Key('testFailure'),
              style: const TextStyle(color: Colors.red)),
        if (_issues != null) ...[
          Text(l.adk_testChecks, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_issues!.isEmpty)
            Text(l.adk_testNoIssues, key: const Key('testNoIssues')),
          for (var i = 0; i < _issues!.length; i++)
            ListTile(
              key: Key('testIssue$i'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  _issues![i].isError ? Icons.error : Icons.warning_amber,
                  color: _issues![i].isError ? Colors.red : Colors.orange),
              title: Text(_issues![i].message),
              subtitle: _issues![i].field == null ? null : Text(_issues![i].field!),
            ),
          const SizedBox(height: 12),
        ],
        if (run != null) ...[
          Text(
            key: const Key('testStatus'),
            l.adk_testStats(
              run.status ?? '',
              run.llmCalls ?? 0,
              run.maxLlmCalls ?? 10,
              run.tokensTotal ?? 0,
              ((run.durationMs ?? 0) / 1000).round(),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (run.error != null)
            Text(run.error!,
                key: const Key('testError'),
                style: const TextStyle(color: Colors.red)),
          if (run.hint != null)
            Text(run.hint!,
                key: const Key('testHint'),
                style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(l.adk_testToolCalls(run.toolCalls.length),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          for (var i = 0; i < run.toolCalls.length; i++)
            _toolCallTile(i, run.toolCalls[i]),
          if ((run.response ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l.adk_testResponse,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(run.response!, key: const Key('testResponse')),
          ],
        ],
      ],
    );
  }

  Widget _toolCallTile(int i, AdkAgentToolCall call) {
    final color = switch (call.decision) {
      'blocked' => Colors.red,
      'approval' => Colors.orange,
      'simulated' => Colors.blue,
      'ok' => Colors.green,
      _ => Colors.grey,
    };
    return ExpansionTile(
      key: Key('testToolCall$i'),
      tilePadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(Icons.circle, size: 12, color: color),
      // only moqui_execute_service runs the service; other tools just name it
      title: Text(call.tool == 'moqui_execute_service'
          ? call.service ?? ''
          : [call.tool, call.service].whereType<String>().join(' ')),
      subtitle: Text(call.decision ?? '…'),
      children: [
        if (call.args != null) SelectableText(call.args!),
        if (call.result != null)
          SelectableText(call.result!, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
