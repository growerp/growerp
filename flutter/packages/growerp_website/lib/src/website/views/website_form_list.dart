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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:growerp_website/l10n/generated/website_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/website_form_bloc.dart';
import 'website_form_dialog.dart';

/// List of website lead-capture forms; embed a form on a content page with
/// `<div data-growerp-form="FORM_ID"></div>`.
class WebsiteFormList extends StatefulWidget {
  const WebsiteFormList({super.key});

  @override
  WebsiteFormListState createState() => WebsiteFormListState();
}

class WebsiteFormListState extends State<WebsiteFormList> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late WebsiteFormBloc _websiteFormBloc;
  List<WebsiteForm> webForms = const <WebsiteForm>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _websiteFormBloc = context.read<WebsiteFormBloc>()
      ..add(const WebsiteFormFetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = WebsiteLocalizations.of(context)!;
    final isPhone = isAPhone(context);

    List<StyledColumn> columns = isPhone
        ? [
            StyledColumn(header: localizations.id, flex: 1),
            StyledColumn(header: localizations.name, flex: 3),
            StyledColumn(header: localizations.tableHdrSubmissions, flex: 2),
            StyledColumn(header: '', flex: 1),
          ]
        : [
            StyledColumn(header: localizations.id, flex: 1),
            StyledColumn(header: localizations.name, flex: 2),
            StyledColumn(header: localizations.title, flex: 3),
            StyledColumn(header: localizations.fields, flex: 1),
            StyledColumn(header: localizations.tableHdrSubmissions, flex: 1),
            StyledColumn(header: '', flex: 1),
          ];

    List<Widget> rowCells(WebsiteForm webForm, int index) {
      Future<void> confirmDelete() async {
        final shouldDelete = await confirmDialog(
          context,
          'Delete form ${webForm.formName}?',
          'This cannot be undone!',
        );
        if (shouldDelete == true) {
          _websiteFormBloc.add(WebsiteFormDelete(webForm));
        }
      }

      final delete = IconButton(
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        onPressed: confirmDelete,
      );
      if (isPhone) {
        return [
          Text(webForm.pseudoId, key: Key('id$index')),
          Text(webForm.formName, key: Key('formName$index')),
          Text('${webForm.submissionCount}'),
          delete,
        ];
      }
      return [
        Text(webForm.pseudoId, key: Key('id$index')),
        Text(webForm.formName, key: Key('formName$index')),
        Text(webForm.title),
        Text('${webForm.fields.length}'),
        Text('${webForm.submissionCount}'),
        delete,
      ];
    }

    return BlocConsumer<WebsiteFormBloc, WebsiteFormState>(
      listener: (context, state) {
        if (state.status == WebsiteFormStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == WebsiteFormStatus.success &&
            (state.message ?? '').isNotEmpty) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == WebsiteFormStatus.loading;
        webForms = state.webForms;
        final rows = webForms
            .map((webForm) => rowCells(webForm, webForms.indexOf(webForm)))
            .toList();
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.searchHintForms,
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                _websiteFormBloc.add(WebsiteFormFetch(searchString: value));
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: columns,
                    rows: rows,
                    isLoading: _isLoading && webForms.isEmpty,
                    onRowTap: (index) async {
                      await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) => Dismissible(
                          key: const Key('websiteFormItem'),
                          direction: DismissDirection.startToEnd,
                          child: BlocProvider.value(
                            value: _websiteFormBloc,
                            child: WebsiteFormDialog(webForms[index]),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: isPhone ? 20 : 50,
                    bottom: 50,
                    child: FloatingActionButton(
                      key: const Key('addNew'),
                      onPressed: () async {
                        await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) => BlocProvider.value(
                            value: _websiteFormBloc,
                            child: WebsiteFormDialog(WebsiteForm()),
                          ),
                        );
                      },
                      tooltip: WebsiteLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
