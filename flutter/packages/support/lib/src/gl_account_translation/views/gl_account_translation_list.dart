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
import '../../../l10n/generated/support_localizations.dart';

/// GL account name translation: translate the ledger account names into the
/// languages the apps support. One row per language, with how much of the chart
/// of accounts it covers.
class GlAccountTranslationList extends StatefulWidget {
  const GlAccountTranslationList({super.key});

  @override
  GlAccountTranslationListState createState() =>
      GlAccountTranslationListState();
}

class GlAccountTranslationListState extends State<GlAccountTranslationList> {
  final _scrollController = ScrollController();
  late GlAccountTranslationBloc _bloc;
  List<GlAccountTranslation> _translations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<GlAccountTranslationBloc>()
      ..add(const GlAccountTranslationFetch(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openDialog(GlAccountTranslation? translation) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: _bloc,
        child: GlAccountTranslationDialog(translation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GlAccountTranslationBloc, GlAccountTranslationState>(
      listener: (context, state) {
        if (state.status == GlAccountTranslationStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        } else if (state.message != null && state.message!.isNotEmpty) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == GlAccountTranslationStatus.loading;
        if (state.status == GlAccountTranslationStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        _translations = state.translations;
        return Scaffold(
          // the route is the form key the route walking tests look for
          key: const Key('/glAccountTranslation'),
          floatingActionButton: FloatingActionButton(
            key: const Key('addNewGlAccountTranslation'),
            onPressed: () => _openDialog(null),
            tooltip: 'Translate the ledger account names',
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              ListFilterBar(
                key: const Key('glAccountTranslationSearch'),
                searchHint: SupportLocalizations.of(
                  context,
                )!.searchHintGlAccountTranslation,
                searchValue: state.searchString,
                onSearchChanged: (value) => _bloc.add(
                  GlAccountTranslationFetch(searchString: value, refresh: true),
                ),
              ),
              Expanded(
                child: _translations.isEmpty && !_isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No ledger account names found.\n\n'
                            'Press + to translate the account names of the '
                            'chart of accounts with AI: the apps then show them '
                            'in the language the user logged in with.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : StyledDataTable(
                        columns: getGlAccountTranslationListColumns(context),
                        rows: _translations
                            .map(
                              (translation) => getGlAccountTranslationListRow(
                                context: context,
                                translation: translation,
                                index: _translations.indexOf(translation),
                                onDelete: (t) =>
                                    _bloc.add(GlAccountTranslationDelete(t)),
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
