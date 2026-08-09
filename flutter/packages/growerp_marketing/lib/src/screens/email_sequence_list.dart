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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/email_sequence_bloc.dart';
import '../bloc/email_sequence_event.dart';
import '../bloc/email_sequence_state.dart';
import 'email_sequence_dialog.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// List of email nurture (drip) sequences.
class EmailSequenceList extends StatefulWidget {
  const EmailSequenceList({super.key});

  @override
  EmailSequenceListState createState() => EmailSequenceListState();
}

class EmailSequenceListState extends State<EmailSequenceList> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late EmailSequenceBloc _emailSequenceBloc;
  List<EmailSequence> emailSequences = const <EmailSequence>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _emailSequenceBloc = context.read<EmailSequenceBloc>()
      ..add(const EmailSequenceFetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MarketingLocalizations.of(context)!;
    final isPhone = isAPhone(context);

    List<StyledColumn> columns = isPhone
        ? [
            StyledColumn(header: localizations.tableHdrId, flex: 1),
            StyledColumn(header: localizations.tableHdrName, flex: 3),
            StyledColumn(header: localizations.active, flex: 1),
            StyledColumn(header: '', flex: 1),
          ]
        : [
            StyledColumn(header: localizations.tableHdrId, flex: 1),
            StyledColumn(header: localizations.tableHdrName, flex: 3),
            StyledColumn(header: localizations.tableHdrStatus, flex: 1),
            StyledColumn(header: localizations.tableHdrSteps, flex: 1),
            StyledColumn(header: localizations.active, flex: 1),
            StyledColumn(header: localizations.tableHdrCompleted, flex: 1),
            StyledColumn(header: '', flex: 1),
          ];

    List<Widget> rowCells(EmailSequence sequence, int index) {
      Future<void> confirmDelete() async {
        final shouldDelete = await confirmDialog(
          context,
          'Delete sequence ${sequence.sequenceName}?',
          'Enrollments will be removed. This cannot be undone!',
        );
        if (shouldDelete == true) {
          _emailSequenceBloc.add(EmailSequenceDelete(sequence));
        }
      }

      final delete = IconButton(
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        onPressed: confirmDelete,
      );
      if (isPhone) {
        return [
          Text(sequence.pseudoId, key: Key('id$index')),
          Text(sequence.sequenceName, key: Key('sequenceName$index')),
          Text('${sequence.activeEnrollments}'),
          delete,
        ];
      }
      return [
        Text(sequence.pseudoId, key: Key('id$index')),
        Text(sequence.sequenceName, key: Key('sequenceName$index')),
        Text(sequence.status),
        Text('${sequence.steps.length}'),
        Text('${sequence.activeEnrollments}'),
        Text('${sequence.completedEnrollments}'),
        delete,
      ];
    }

    return BlocConsumer<EmailSequenceBloc, EmailSequenceState>(
      listener: (context, state) {
        if (state.status == EmailSequenceStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == EmailSequenceStatus.success &&
            (state.message ?? '').isNotEmpty) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == EmailSequenceStatus.loading;
        emailSequences = state.emailSequences;
        final rows = emailSequences
            .map(
              (sequence) =>
                  rowCells(sequence, emailSequences.indexOf(sequence)),
            )
            .toList();
        return Column(
          children: [
            ListFilterBar(
              searchHint: 'search in name...',
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                _emailSequenceBloc.add(EmailSequenceFetch(searchString: value));
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: columns,
                    rows: rows,
                    isLoading: _isLoading && emailSequences.isEmpty,
                    onRowTap: (index) async {
                      await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) => Dismissible(
                          key: const Key('emailSequenceItem'),
                          direction: DismissDirection.startToEnd,
                          child: BlocProvider.value(
                            value: _emailSequenceBloc,
                            child: EmailSequenceDialog(emailSequences[index]),
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
                            value: _emailSequenceBloc,
                            child: EmailSequenceDialog(EmailSequence()),
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
