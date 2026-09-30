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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_insurance.dart';

/// Client assistant: questions about the client's own policies and claims,
/// answered at any hour instead of waiting on the hotline. Questions it
/// cannot answer are passed on to the agency.
class InsuranceAssistantDialog extends StatefulWidget {
  const InsuranceAssistantDialog({super.key});

  @override
  InsuranceAssistantDialogState createState() =>
      InsuranceAssistantDialogState();
}

class InsuranceAssistantDialogState extends State<InsuranceAssistantDialog> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _waiting = false;

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Dialog(
      key: const Key('InsuranceAssistantDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.assistant,
        height: 640,
        width: 460,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('assistantMessages'),
                controller: _scrollController,
                children: [
                  _bubble(localizations.assistantWelcome, false, theme),
                  for (final (index, message) in _messages.indexed)
                    _bubble(
                      message['text']!,
                      message['role'] == 'user',
                      theme,
                      key: Key('assistantMessage$index'),
                    ),
                  if (_waiting) const LoadingIndicator(),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('assistantQuestion'),
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: localizations.assistantHint,
                    ),
                    onSubmitted: (_) => _ask(),
                  ),
                ),
                IconButton(
                  key: const Key('assistantSend'),
                  icon: const Icon(Icons.send),
                  onPressed: _waiting ? null : _ask,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, bool mine, ThemeData theme, {Key? key}) => Align(
    key: key,
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: mine
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    ),
  );

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _waiting) return;
    final localizations = InsuranceLocalizations.of(context)!;
    final history = List<Map<String, String>>.from(_messages);
    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _questionController.clear();
      _waiting = true;
    });
    String answer;
    try {
      var result = await context.read<RestClient>().askInsuranceAssistant(
        question: question,
        history: history,
      );
      if (result is String) result = jsonDecode(result);
      answer = result['answer']?.toString() ?? '';
      if (result['escalated'] == true) {
        answer = '$answer\n\n${localizations.assistantEscalated}';
      }
    } catch (e) {
      answer = await getDioError(e);
    }
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'text': answer});
      _waiting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
