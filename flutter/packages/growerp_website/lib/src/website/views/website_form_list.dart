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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
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
    final isPhone = isAPhone(context);

    List<StyledColumn> columns = isPhone
        ? [
            StyledColumn(header: 'ID', flex: 1),
            StyledColumn(header: 'Name', flex: 3),
            StyledColumn(header: 'Submissions', flex: 2),
            StyledColumn(header: '', flex: 1),
          ]
        : [
            StyledColumn(header: 'ID', flex: 1),
            StyledColumn(header: 'Name', flex: 2),
            StyledColumn(header: 'Title', flex: 3),
            StyledColumn(header: 'Fields', flex: 1),
            StyledColumn(header: 'Submissions', flex: 1),
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
              searchHint: 'search in name, title...',
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
                      tooltip: 'Add new',
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
