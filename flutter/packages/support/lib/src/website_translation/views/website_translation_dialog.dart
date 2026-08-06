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

import '../website_translation.dart';

/// New translation: the form. Existing translation: progress and result.
class WebsiteTranslationDialog extends StatefulWidget {
  final WebsiteTranslation? translation;
  const WebsiteTranslationDialog(this.translation, {super.key});

  @override
  WebsiteTranslationDialogState createState() =>
      WebsiteTranslationDialogState();
}

class WebsiteTranslationDialogState extends State<WebsiteTranslationDialog> {
  final _formKey = GlobalKey<FormState>();
  late WebsiteTranslationBloc _bloc;
  late RestClient _restClient;

  Company? _owner;
  String _sourceLocale = 'en';
  final Set<String> _targetLocales = {};
  bool _translateEntityNames = false;
  bool _overwriteExisting = false;

  bool get _isNew => widget.translation == null;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<WebsiteTranslationBloc>();
    _restClient = context.read<RestClient>();
  }

  /// the freshest version of this row, updated by the polling in the bloc
  WebsiteTranslation _current(WebsiteTranslationState state) {
    final id = widget.translation!.translationId;
    if (state.selected?.translationId == id) return state.selected!;
    return state.translations.firstWhere(
      (t) => t.translationId == id,
      orElse: () => widget.translation!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebsiteTranslationBloc, WebsiteTranslationState>(
      listener: (context, state) {
        // only a real user action closes this dialog, never a background poll
        if (state.status == WebsiteTranslationStatus.success && _isNew) {
          Navigator.of(context).pop();
        }
        if (state.status == WebsiteTranslationStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          key: const Key('WebsiteTranslationDialog'),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: popUp(
            context: context,
            title: _isNew ? 'Translate a website' : 'Website translation',
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
  Widget _newForm(WebsiteTranslationState state) {
    if (state.status == WebsiteTranslationStatus.loading) {
      return const LoadingIndicator();
    }
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Every page of this website is translated with AI and published '
              'next to the original, reachable under its language: /th/, /de/ '
              'and so on. This takes a few minutes and uses AI credits.',
            ),
            const SizedBox(height: 16),
            AutocompleteLabel<Company>(
              key: const Key('ownerPartyId'),
              label: 'Owner',
              hintText: 'the owner whose website is translated',
              optionsBuilder: (TextEditingValue value) async {
                final result = await _restClient.getCompanies(
                  mainCompanies: true,
                  searchString: value.text.isEmpty ? null : value.text,
                  limit: 20,
                );
                return result.companies;
              },
              displayStringForOption: (Company company) =>
                  company.name ?? company.partyId ?? '',
              onSelected: (Company? company) =>
                  setState(() => _owner = company),
              validator: (Company? company) =>
                  company == null ? 'Select the owner' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const Key('sourceLocale'),
              decoration: const InputDecoration(
                labelText: 'Written in',
                helperText: 'the language the pages are written in now',
              ),
              initialValue: _sourceLocale,
              items: WebsiteTranslation.localeNames.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _sourceLocale = value ?? 'en';
                _targetLocales.remove(_sourceLocale);
              }),
            ),
            const SizedBox(height: 10),
            const Text('Translate into'),
            // the languages the apps support, minus the one it is written in
            ...WebsiteTranslation.localeNames.keys
                .where((locale) => locale != _sourceLocale)
                .map(
                  (locale) => CheckboxListTile(
                    key: Key('locale_$locale'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      '${WebsiteTranslation.localeNames[locale]} ($locale)',
                    ),
                    value: _targetLocales.contains(locale),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _targetLocales.add(locale);
                      } else {
                        _targetLocales.remove(locale);
                      }
                    }),
                  ),
                ),
            const Divider(),
            CheckboxListTile(
              key: const Key('translateEntityNames'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Also product and category names'),
              value: _translateEntityNames,
              onChanged: (checked) =>
                  setState(() => _translateEntityNames = checked == true),
            ),
            CheckboxListTile(
              key: const Key('overwriteExisting'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Redo pages already translated'),
              value: _overwriteExisting,
              onChanged: (checked) =>
                  setState(() => _overwriteExisting = checked == true),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                key: const Key('startTranslation'),
                child: const Text('Start translation'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_targetLocales.isEmpty) {
                    HelperFunctions.showMessage(
                      context,
                      'Select at least one language',
                      Colors.red,
                    );
                    return;
                  }
                  _bloc.add(
                    WebsiteTranslationCreate(
                      ownerPartyId: _owner!.partyId!,
                      sourceLocale: _sourceLocale,
                      targetLocales: _targetLocales.join(','),
                      translateEntityNames: _translateEntityNames,
                      overwriteExisting: _overwriteExisting,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // existing translation
  // --------------------------------------------------------------------------
  Widget _detail(WebsiteTranslation t) {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _row('Owner', t.ownerName.isEmpty ? t.ownerPartyId : t.ownerName),
          _row('Store', t.productStoreId),
          _row(
            'Written in',
            WebsiteTranslation.localeNames[t.sourceLocale] ?? t.sourceLocale,
          ),
          _row('Languages', t.targetLanguageNames),
          const Divider(),
          Row(
            children: [
              if (t.inProgress)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Expanded(
                child: Text(
                  t.status,
                  key: const Key('detailStatus'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: t.isFailed
                        ? Theme.of(context).colorScheme.error
                        : t.isCompleted
                        ? Colors.green
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (t.statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t.statusMessage),
            ),
          if (t.pageCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: t.pageCount == 0
                    ? 0
                    : (t.translatedCount ?? 0) / t.pageCount!,
              ),
            ),
          _row('Pages', '${t.translatedCount ?? 0} / ${t.pageCount ?? 0}'),
          if (t.isFailed && t.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              t.errorMessage,
              key: const Key('errorMessage'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (t.isCompleted) ...[
            const Divider(),
            Text(
              'The translated pages are on the site under their language, for '
              'example /${t.targetLocaleList.isEmpty ? 'th' : t.targetLocaleList.first}/. '
              'They are normal website pages: edit or remove them in the '
              'website screen of the owner.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              key: const Key('deleteTranslation'),
              child: const Text('Remove from list'),
              onPressed: () {
                _bloc.add(WebsiteTranslationDelete(t));
                Navigator.of(context).pop();
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Removing only clears this row, the translated pages stay.',
              style: TextStyle(fontSize: 12),
            ),
          ),
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
