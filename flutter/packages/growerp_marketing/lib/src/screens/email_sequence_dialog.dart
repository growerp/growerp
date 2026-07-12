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
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/email_sequence_bloc.dart';
import '../bloc/email_sequence_event.dart';
import '../bloc/email_sequence_state.dart';

class EmailSequenceDialog extends StatefulWidget {
  final EmailSequence emailSequence;
  const EmailSequenceDialog(this.emailSequence, {super.key});

  @override
  EmailSequenceDialogState createState() => EmailSequenceDialogState();
}

class _StepRow {
  final TextEditingController delayDays = TextEditingController(text: '0');
  final TextEditingController subject = TextEditingController();
  final TextEditingController bodyHtml = TextEditingController();
}

class EmailSequenceDialogState extends State<EmailSequenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _active = true;
  final List<_StepRow> _stepRows = [];
  late EmailSequenceBloc _emailSequenceBloc;

  @override
  void initState() {
    super.initState();
    _emailSequenceBloc = context.read<EmailSequenceBloc>();
    _nameController.text = widget.emailSequence.sequenceName;
    _active = widget.emailSequence.status != 'PAUSED';
    for (final step in widget.emailSequence.steps) {
      final row = _StepRow();
      row.delayDays.text = '${step.delayDays}';
      row.subject.text = step.subject;
      row.bodyHtml.text = step.bodyHtml;
      _stepRows.add(row);
    }
    if (_stepRows.isEmpty) _stepRows.add(_StepRow());
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocListener<EmailSequenceBloc, EmailSequenceState>(
      listener: (context, state) {
        if (state.status == EmailSequenceStatus.success) {
          Navigator.of(context).pop();
        }
        if (state.status == EmailSequenceStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      child: Dialog(
        key: const Key('EmailSequenceDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: widget.emailSequence.emailSequenceId.isEmpty
              ? 'New Email Sequence'
              : 'Email Sequence #${widget.emailSequence.pseudoId}',
          width: isPhone ? 400 : 800,
          height: 650,
          child: _dialogContent(),
        ),
      ),
    );
  }

  Widget _dialogContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const Key('listView'),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('sequenceName'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Sequence Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Name required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Active'),
                Switch(
                  key: const Key('sequenceActive'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Steps — use {name} for the recipient name, '
                '{track:https://...} for tracked links',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ..._stepRows.map((row) {
              final index = _stepRows.indexOf(row);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Step ${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              key: Key('stepDelay$index'),
                              controller: row.delayDays,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Delay (days)',
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            key: Key('stepDelete$index'),
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                setState(() => _stepRows.remove(row)),
                          ),
                        ],
                      ),
                      TextFormField(
                        key: Key('stepSubject$index'),
                        controller: row.subject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      TextFormField(
                        key: Key('stepBody$index'),
                        controller: row.bodyHtml,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Body (HTML allowed)',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('addStep'),
                onPressed: () => setState(() => _stepRows.add(_StepRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add step'),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      widget.emailSequence.emailSequenceId.isEmpty
                          ? 'Create'
                          : 'Update',
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _emailSequenceBloc.add(
                          EmailSequenceUpdate(
                            widget.emailSequence.copyWith(
                              sequenceName: _nameController.text,
                              status: _active ? 'ACTIVE' : 'PAUSED',
                              steps: _stepRows
                                  .map(
                                    (row) => EmailSequenceStep(
                                      stepSeq: _stepRows.indexOf(row) + 1,
                                      delayDays:
                                          int.tryParse(row.delayDays.text) ?? 0,
                                      subject: row.subject.text,
                                      bodyHtml: row.bodyHtml.text,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
