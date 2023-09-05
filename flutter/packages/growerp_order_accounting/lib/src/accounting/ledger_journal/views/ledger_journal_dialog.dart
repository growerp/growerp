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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_order_accounting/src/findoc/views/views.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';

import '../ledger_journal.dart';

class LedgerJournalDialog extends StatefulWidget {
  final LedgerJournal ledgerJournal;
  const LedgerJournalDialog(this.ledgerJournal, {super.key});
  @override
  LedgerJournalDialogState createState() => LedgerJournalDialogState();
}

class LedgerJournalDialogState extends State<LedgerJournalDialog> {
  final _formKeyLedgerJournal = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late LedgerJournalBloc _ledgerJournalBloc;

  @override
  void initState() {
    super.initState();
    _ledgerJournalBloc = context.read<LedgerJournalBloc>();
    if (widget.ledgerJournal.journalId.isNotEmpty) {
      _nameController.text = widget.ledgerJournal.journalName;
      _descriptionController.text = widget.ledgerJournal.journalName;
    }
  }

  @override
  Widget build(BuildContext context) {
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    return BlocListener<LedgerJournalBloc, LedgerJournalState>(
        listener: (context, state) async {
          switch (state.status) {
            case LedgerJournalStatus.success:
              Navigator.of(context).pop();
              break;
            case LedgerJournalStatus.failure:
              HelperFunctions.showMessage(
                  context, 'Error: ${state.message}', Colors.red);
              break;
            default:
              const Text("????");
          }
        },
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Dialog(
                key: const Key('LedgerJournalDialog'),
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                    context: context,
                    title:
                        "LedgerJournal #${widget.ledgerJournal.journalId.isEmpty ? " New" : widget.ledgerJournal.journalId}",
                    width: columns.toDouble() * 400,
                    height: 1 / columns.toDouble() * 1200,
                    child: _ledgerJournalForm()))));
  }

  Widget _ledgerJournalForm() {
    List<Widget> widgets = [
      TextFormField(
        key: const Key('name'),
        decoration: const InputDecoration(labelText: 'LedgerJournal Name'),
        controller: _nameController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a ledgerJournal name?' : null;
        },
      ),
      Row(
        children: [
          if (widget.ledgerJournal.journalId.isNotEmpty)
            ElevatedButton(
                key: const Key('post'),
                child: const Text('Post'),
                onPressed: () {
                  if (_formKeyLedgerJournal.currentState!.validate()) {
                    _ledgerJournalBloc.add(LedgerJournalUpdate(LedgerJournal(
                      journalId: widget.ledgerJournal.journalId,
                      journalName: _nameController.text,
                      isPosted: true,
                    )));
                  }
                }),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
                key: const Key('update'),
                child: Text(widget.ledgerJournal.journalId.isEmpty
                    ? 'Create'
                    : 'Update'),
                onPressed: () {
                  if (_formKeyLedgerJournal.currentState!.validate()) {
                    _ledgerJournalBloc.add(LedgerJournalUpdate(LedgerJournal(
                      journalId: widget.ledgerJournal.journalId,
                      journalName: _nameController.text,
                    )));
                  }
                }),
          ),
        ],
      ),
    ];

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(widgets[i]);
      // no space at the end
      if (i < widgets.length - 1) column.add(const SizedBox(height: 10));
    }

    return Column(children: [
      Form(
          key: _formKeyLedgerJournal,
          child: SingleChildScrollView(
            key: const Key('listView'),
            padding: const EdgeInsets.all(20),
            child: Column(children: (rows.isEmpty ? column : rows)),
          )),
      if (widget.ledgerJournal.journalId.isNotEmpty)
        Flexible(
          child: FinDocListForm(
            sales: true,
            docType: FinDocType.transaction,
            journalId: widget.ledgerJournal.journalId,
          ),
        )
    ]);
  }
}
