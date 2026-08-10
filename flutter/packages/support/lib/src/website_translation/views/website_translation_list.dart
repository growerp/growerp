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
import '../../../l10n/generated/support_localizations.dart';

/// Website translation: translate an owner's website into the languages the
/// apps support. Each row is one run; the ones still running refresh themselves.
class WebsiteTranslationList extends StatefulWidget {
  const WebsiteTranslationList({super.key});

  @override
  WebsiteTranslationListState createState() => WebsiteTranslationListState();
}

class WebsiteTranslationListState extends State<WebsiteTranslationList> {
  final _scrollController = ScrollController();
  late WebsiteTranslationBloc _bloc;
  List<WebsiteTranslation> _translations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<WebsiteTranslationBloc>()
      ..add(const WebsiteTranslationFetch(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openDialog(WebsiteTranslation? translation) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: _bloc,
        child: WebsiteTranslationDialog(translation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebsiteTranslationBloc, WebsiteTranslationState>(
      listener: (context, state) {
        if (state.status == WebsiteTranslationStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        } else if (state.message != null && state.message!.isNotEmpty) {
          // covers both "started in the background" and the poll noticing that a
          // translation finished; a poll without news carries no message
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == WebsiteTranslationStatus.loading;
        if (state.status == WebsiteTranslationStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        _translations = state.translations;
        return Scaffold(
          // the route is the form key the route walking tests look for
          key: const Key('/websiteTranslation'),
          floatingActionButton: FloatingActionButton(
            key: const Key('addNewWebsiteTranslation'),
            onPressed: () => _openDialog(null),
            tooltip: 'Translate a website',
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              ListFilterBar(
                key: const Key('websiteTranslationSearch'),
                searchHint: SupportLocalizations.of(
                  context,
                )!.searchHintWebsiteTranslation,
                searchValue: state.searchString,
                onSearchChanged: (value) => _bloc.add(
                  WebsiteTranslationFetch(searchString: value, refresh: true),
                ),
              ),
              Expanded(
                child: _translations.isEmpty && !_isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No websites translated yet.\n\n'
                            'Press + to translate the website of an owner into '
                            'the languages the apps support: every page is '
                            'rewritten with AI and published next to the '
                            'original, reachable at /th/, /de/ and so on.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : StyledDataTable(
                        columns: getWebsiteTranslationListColumns(context),
                        rows: _translations
                            .map(
                              (translation) => getWebsiteTranslationListRow(
                                context: context,
                                translation: translation,
                                index: _translations.indexOf(translation),
                                onDelete: (t) =>
                                    _bloc.add(WebsiteTranslationDelete(t)),
                              ),
                            )
                            .toList(),
                        isLoading: _isLoading && _translations.isEmpty,
                        scrollController: _scrollController,
                        rowHeight: isAPhone(context) ? 72 : 56,
                        onRowTap: (index) => _openDialog(_translations[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
