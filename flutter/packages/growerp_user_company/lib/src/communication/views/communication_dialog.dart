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
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

import '../communication.dart';

/// Add, show, update or delete one communication. A system email (isAuto)
/// is read only.
class CommunicationDialog extends StatefulWidget {
  const CommunicationDialog(this.communicationEvent, {super.key});
  final CommunicationEvent communicationEvent;

  @override
  CommunicationDialogState createState() => CommunicationDialogState();
}

class CommunicationDialogState extends State<CommunicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _noteController = TextEditingController();
  late CommunicationEventType _type;
  late CommunicationDirection _direction;
  late DateTime _entryDate;
  late bool _readOnly;
  late UserCompanyLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    final event = widget.communicationEvent;
    _type = event.type ?? CommunicationEventType.phone;
    _direction = event.direction ?? CommunicationDirection.outgoing;
    _entryDate = (event.entryDate ?? CustomizableDateTime.current).toLocal();
    _readOnly = event.isAuto == true;
    _subjectController.text = event.subject ?? '';
    // system emails are mostly html: show them as plain text
    _bodyController.text = _readOnly && event.contentType == 'text/html'
        ? _htmlToText(event.body ?? '')
        : event.body ?? '';
    _noteController.text = event.note ?? '';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _htmlToText(String html) => html
      .replaceAll(RegExp(r'<(style|script)[^>]*>.*?</\1>', dotAll: true), '')
      .replaceAll(RegExp(r'<br\s*/?>|</p>|</div>|</tr>|</h\d>'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: CustomizableDateTime.current.add(const Duration(days: 365)),
      locale: context.read<LocaleBloc>().state.locale,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entryDate),
    );
    setState(() {
      _entryDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _entryDate.hour,
        time?.minute ?? _entryDate.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _localizations = UserCompanyLocalizations.of(context)!;
    final event = widget.communicationEvent;
    return Dialog(
      key: const Key('CommunicationDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<CommunicationBloc, CommunicationState>(
        // only this dialog's own write closes it, not a background fetch
        listenWhen: (previous, current) =>
            previous.status == CommunicationStatus.loading &&
            current.status == CommunicationStatus.success &&
            current.action != null,
        listener: (context, state) => Navigator.of(context).pop(),
        child: popUp(
          context: context,
          title: event.communicationEventId == null
              ? _localizations.commNew
              : '${_localizations.communication} #${event.communicationEventId}',
          height: isAPhone(context) ? 700 : 600,
          width: isAPhone(context) ? 400 : 600,
          child: _form(),
        ),
      ),
    );
  }

  Widget _form() {
    final event = widget.communicationEvent;
    final types = CommunicationEventType.values
        .where((t) => _readOnly || t != CommunicationEventType.autoEmail)
        .toList();
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const Key('communicationDialogListView'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_readOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _localizations.commAutoEmailReadOnly,
                  key: const Key('readOnly'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CommunicationEventType>(
                    key: const Key('type'),
                    initialValue: _type,
                    decoration: InputDecoration(
                      labelText: _localizations.commType,
                    ),
                    items: [
                      for (final t in types)
                        DropdownMenuItem(
                          key: Key('type_${t.name}'),
                          value: t,
                          child: Row(
                            children: [
                              Icon(communicationTypeIcon(t), size: 18),
                              const SizedBox(width: 8),
                              Text(communicationTypeLabel(_localizations, t)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: _readOnly
                        ? null
                        : (value) => setState(() => _type = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<CommunicationDirection>(
                    key: const Key('direction'),
                    initialValue: _direction,
                    decoration: InputDecoration(
                      labelText: _localizations.commDirection,
                    ),
                    items: [
                      DropdownMenuItem(
                        key: const Key('direction_outgoing'),
                        value: CommunicationDirection.outgoing,
                        child: Text(_localizations.commOutgoing),
                      ),
                      DropdownMenuItem(
                        key: const Key('direction_incoming'),
                        value: CommunicationDirection.incoming,
                        child: Text(_localizations.commIncoming),
                      ),
                    ],
                    onChanged: _readOnly
                        ? null
                        : (value) => setState(() => _direction = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _localizations.commDate,
                    ),
                    child: Text(
                      _entryDate.toString().substring(0, 16),
                      key: const Key('entryDate'),
                    ),
                  ),
                ),
                if (!_readOnly) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    key: const Key('setDate'),
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _selectDateTime,
                  ),
                ],
              ],
            ),
            if (event.communicationEventId != null) ...[
              const SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(labelText: _localizations.commWith),
                child: Text(
                  '${event.fromPartyName ?? ''} → ${event.toPartyName ?? ''}',
                  key: const Key('parties'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('subject'),
              readOnly: _readOnly,
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: _localizations.commSubject,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? _localizations.commSubject
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('body'),
              readOnly: _readOnly,
              controller: _bodyController,
              minLines: 4,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: _localizations.commBody,
                alignLabelWithHint: true,
              ),
            ),
            if (!_readOnly) ...[
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('note'),
                controller: _noteController,
                decoration: InputDecoration(labelText: _localizations.commNote),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (event.communicationEventId != null) ...[
                    OutlinedButton(
                      key: const Key('deleteCommunication'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => context.read<CommunicationBloc>().add(
                        CommunicationDelete(event),
                      ),
                      child: Text(_localizations.delete),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('updateCommunication'),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        context.read<CommunicationBloc>().add(
                          CommunicationUpdate(
                            event.copyWith(
                              type: _type,
                              direction: _direction,
                              entryDate: _entryDate,
                              subject: _subjectController.text,
                              body: _bodyController.text,
                              note: _noteController.text,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        event.communicationEventId == null
                            ? _localizations.create
                            : _localizations.update,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
