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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../gl_account_translation.dart';

/// New translation: pick the language the account names are written in and the
/// languages to translate into. Existing row: its coverage.
class GlAccountTranslationDialog extends StatefulWidget {
  final GlAccountTranslation? translation;
  const GlAccountTranslationDialog(this.translation, {super.key});

  @override
  GlAccountTranslationDialogState createState() =>
      GlAccountTranslationDialogState();
}

class GlAccountTranslationDialogState
    extends State<GlAccountTranslationDialog> {
  late GlAccountTranslationBloc _bloc;

  String _sourceLocale = 'en';
  String? _targetLocale;

  bool get _isNew => widget.translation == null;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<GlAccountTranslationBloc>();
    _targetLocale = widget.translation?.locale;
  }

  /// the freshest version of this row, updated by the polling in the bloc
  GlAccountTranslation _current(GlAccountTranslationState state) {
    return state.translations.firstWhere(
      (t) => t.locale == widget.translation!.locale,
      orElse: () => widget.translation!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GlAccountTranslationBloc, GlAccountTranslationState>(
      listener: (context, state) {
        // only a real user action closes this dialog, never a background poll
        if (state.status == GlAccountTranslationStatus.success && _isNew) {
          Navigator.of(context).pop();
        }
        if (state.status == GlAccountTranslationStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          key: const Key('GlAccountTranslationDialog'),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: popUp(
            context: context,
            title: _isNew
                ? 'Translate the account names'
                : 'Account name translation',
            height: 620,
            width: 450,
            child: _isNew ? _newForm(state) : _detail(_current(state)),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // new translation
  // --------------------------------------------------------------------------
  Widget _newForm(GlAccountTranslationState state) {
    if (state.status == GlAccountTranslationStatus.loading) {
      return const LoadingIndicator();
    }
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'The ledger account names of every company, and the account class '
            'and type descriptions, are translated with AI and stored per '
            'language. An app shows them in the language the user logged in '
            'with, and falls back to the stored text where there is no '
            'translation. This takes a few minutes and uses AI credits.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('sourceLocale'),
            decoration: const InputDecoration(
              labelText: 'Written in',
              helperText: 'the language the stored ledger texts are in',
            ),
            initialValue: _sourceLocale,
            items: GlAccountTranslation.localeNames.entries
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _sourceLocale = value ?? 'en';
              if (_targetLocale == _sourceLocale) _targetLocale = null;
            }),
          ),
          const SizedBox(height: 10),
          // one language per run: the names of the whole chart of accounts go
          // through the AI, which takes minutes
          DropdownButtonFormField<String>(
            key: const Key('targetLocale'),
            decoration: const InputDecoration(labelText: 'Translate into'),
            initialValue: _targetLocale,
            items: GlAccountTranslation.localeNames.entries
                .where((e) => e.key != _sourceLocale)
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text('${e.value} (${e.key})'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _targetLocale = value),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              key: const Key('startTranslation'),
              child: const Text('Start translation'),
              onPressed: () {
                if (_targetLocale == null) {
                  HelperFunctions.showMessage(
                    context,
                    'Select the language to translate into',
                    Colors.red,
                  );
                  return;
                }
                _bloc.add(
                  GlAccountTranslationCreate(
                    sourceLocale: _sourceLocale,
                    targetLocale: _targetLocale!,
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Texts that already have a translation are kept: remove the '
              'language first to redo it.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // existing language
  // --------------------------------------------------------------------------
  Widget _detail(GlAccountTranslation t) {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _row('Language', '${t.language} (${t.locale})'),
          _row('Status', t.status),
          _row('Texts', '${t.translatedCount} / ${t.nameCount}'),
          if (t.nameCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: t.translatedCount / t.nameCount,
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              key: const Key('translateRest'),
              child: Text(
                t.isCompleted ? 'Translate again' : 'Translate the rest',
              ),
              onPressed: () {
                _bloc.add(
                  GlAccountTranslationCreate(
                    sourceLocale: 'en',
                    targetLocale: t.locale,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
          if (t.translatedCount > 0) ...[
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton(
                key: const Key('deleteTranslation'),
                child: const Text('Remove this language'),
                onPressed: () {
                  _bloc.add(GlAccountTranslationDelete(t));
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Removing only clears the translations, the ledger texts '
                'themselves stay as they are.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
