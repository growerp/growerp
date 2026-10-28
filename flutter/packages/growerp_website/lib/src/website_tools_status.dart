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

import '../l10n/generated/website_localizations.dart';
import 'website_conversion/website_conversion.dart';
import 'website_translation/website_translation.dart';

/// The website tools of a tenant: it has a single website, so instead of the
/// lists system support uses this shows the status of the latest conversion
/// and the latest translation, with a button to start a new one.
class WebsiteToolsStatus extends StatefulWidget {
  const WebsiteToolsStatus({super.key});

  @override
  WebsiteToolsStatusState createState() => WebsiteToolsStatusState();
}

class WebsiteToolsStatusState extends State<WebsiteToolsStatus> {
  late WebsiteConversionBloc _conversionBloc;
  late WebsiteTranslationBloc _translationBloc;

  @override
  void initState() {
    super.initState();
    _conversionBloc = context.read<WebsiteConversionBloc>()
      ..add(const WebsiteConversionFetch(refresh: true));
    _translationBloc = context.read<WebsiteTranslationBloc>()
      ..add(const WebsiteTranslationFetch(refresh: true));
  }

  void _showMessage(String? message, bool failed) {
    // a poll without news carries no message
    if (!failed && (message == null || message.isEmpty)) return;
    HelperFunctions.showMessage(
      context,
      '$message',
      failed ? Colors.red : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = WebsiteLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<WebsiteConversionBloc, WebsiteConversionState>(
          listener: (context, state) => _showMessage(
            state.message,
            state.status == WebsiteConversionStatus.failure,
          ),
        ),
        BlocListener<WebsiteTranslationBloc, WebsiteTranslationState>(
          listener: (context, state) => _showMessage(
            state.message,
            state.status == WebsiteTranslationStatus.failure,
          ),
        ),
      ],
      child: ListView(
        key: const Key('/websiteTools'),
        padding: const EdgeInsets.all(16),
        children: [
          BlocBuilder<WebsiteConversionBloc, WebsiteConversionState>(
            builder: (context, state) {
              final c = state.conversions.isEmpty
                  ? null
                  : state.conversions.first;
              return _card(
                key: const Key('conversionStatus'),
                icon: Icons.web,
                title: localizations.websiteConversionTitle,
                loading: state.status == WebsiteConversionStatus.initial,
                empty: localizations.noConversionTenant,
                lines: c == null
                    ? null
                    : [
                        _row(localizations.website, c.sourceUrl),
                        _status(
                          c.status,
                          c.inProgress,
                          c.isFailed,
                          c.isCompleted,
                        ),
                        if (c.statusMessage.isNotEmpty) Text(c.statusMessage),
                        if (c.isCompleted)
                          _row(
                            localizations.pagesImagesLabel,
                            '${c.pageCount ?? 0} / ${c.imageCount ?? 0}',
                          ),
                        if (c.isFailed && c.errorMessage.isNotEmpty)
                          _error(c.errorMessage),
                      ],
                button: OutlinedButton(
                  key: const Key('addNewWebsiteConversion'),
                  onPressed: c?.inProgress == true
                      ? null
                      : () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: _conversionBloc,
                            child: const WebsiteConversionDialog(null),
                          ),
                        ),
                  child: Text(localizations.convertWebsite),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<WebsiteTranslationBloc, WebsiteTranslationState>(
            builder: (context, state) {
              final t = state.translations.isEmpty
                  ? null
                  : state.translations.first;
              return _card(
                key: const Key('translationStatus'),
                icon: Icons.translate,
                title: localizations.websiteTranslationTitle,
                loading: state.status == WebsiteTranslationStatus.initial,
                empty: localizations.noTranslationTenant,
                lines: t == null
                    ? null
                    : [
                        _row(
                          localizations.languagesLabel,
                          t.targetLanguageNames,
                        ),
                        _status(
                          t.status,
                          t.inProgress,
                          t.isFailed,
                          t.isCompleted,
                        ),
                        if (t.statusMessage.isNotEmpty) Text(t.statusMessage),
                        if (t.inProgress && t.pageCount != null)
                          LinearProgressIndicator(
                            value: t.pageCount == 0
                                ? 0
                                : (t.translatedCount ?? 0) / t.pageCount!,
                          ),
                        if (t.pageCount != null)
                          _row(
                            localizations.pagesLabel,
                            '${t.translatedCount ?? 0} / ${t.pageCount}',
                          ),
                        if (t.isFailed && t.errorMessage.isNotEmpty)
                          _error(t.errorMessage),
                      ],
                button: OutlinedButton(
                  key: const Key('addNewWebsiteTranslation'),
                  onPressed: t?.inProgress == true
                      ? null
                      : () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: _translationBloc,
                            child: const WebsiteTranslationDialog(null),
                          ),
                        ),
                  child: Text(localizations.translateWebsite),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// [lines] null: nothing ran yet, show [empty] instead
  Widget _card({
    required Key key,
    required IconData icon,
    required String title,
    required bool loading,
    required String empty,
    required List<Widget>? lines,
    required Widget button,
  }) {
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: LoadingIndicator())
            else if (lines == null)
              Text(empty)
            else
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: line,
                ),
              ),
            const SizedBox(height: 12),
            Center(child: button),
          ],
        ),
      ),
    );
  }

  Widget _status(String status, bool inProgress, bool failed, bool completed) {
    return Row(
      children: [
        if (inProgress)
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
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: failed
                  ? Theme.of(context).colorScheme.error
                  : completed
                  ? Colors.green
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _error(String message) => Text(
    message,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}
