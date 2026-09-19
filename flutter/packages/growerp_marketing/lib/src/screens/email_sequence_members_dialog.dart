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
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/email_sequence_bloc.dart';
import '../bloc/email_sequence_event.dart';
import '../bloc/email_sequence_state.dart';

/// Manage the members (enrollments) of one email nurture sequence:
/// list, manually add, and unsubscribe.
class EmailSequenceMembersDialog extends StatefulWidget {
  final EmailSequence emailSequence;
  const EmailSequenceMembersDialog(this.emailSequence, {super.key});

  @override
  EmailSequenceMembersDialogState createState() =>
      EmailSequenceMembersDialogState();
}

class EmailSequenceMembersDialogState
    extends State<EmailSequenceMembersDialog> {
  final _addFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  late EmailSequenceBloc _emailSequenceBloc;

  @override
  void initState() {
    super.initState();
    _emailSequenceBloc = context.read<EmailSequenceBloc>()
      ..add(EmailSequenceMembersFetch(widget.emailSequence.emailSequenceId));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocListener<EmailSequenceBloc, EmailSequenceState>(
      listenWhen: (previous, current) =>
          previous.memberStatus != current.memberStatus,
      listener: (context, state) {
        if (state.memberStatus == EmailSequenceStatus.success) {
          _emailController.clear();
          _firstNameController.clear();
        }
        if (state.memberStatus == EmailSequenceStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${state.memberMessage}',
            Colors.red,
          );
        }
      },
      child: Dialog(
        key: const Key('EmailSequenceMembersDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: 'Members of ${widget.emailSequence.sequenceName}',
          width: isPhone ? 400 : 800,
          height: 650,
          child: _dialogContent(),
        ),
      ),
    );
  }

  Widget _dialogContent() {
    return Column(
      children: [
        Form(
          key: _addFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: const Key('memberEmail'),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Email required'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const Key('memberFirstName'),
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const Key('addMember'),
                icon: const Icon(Icons.add),
                tooltip: 'Add member',
                onPressed: () {
                  if (_addFormKey.currentState!.validate()) {
                    _emailSequenceBloc.add(
                      EmailSequenceMemberAdd(
                        emailSequenceId: widget.emailSequence.emailSequenceId,
                        emailAddress: _emailController.text,
                        firstName: _firstNameController.text,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _memberTable()),
      ],
    );
  }

  Widget _memberTable() {
    return BlocBuilder<EmailSequenceBloc, EmailSequenceState>(
      builder: (context, state) {
        final members = state.members;
        final columns = [
          const StyledColumn(header: 'Email', flex: 3),
          const StyledColumn(header: 'Name', flex: 2),
          const StyledColumn(header: 'Status', flex: 1),
          const StyledColumn(header: 'Step', flex: 1),
          const StyledColumn(header: '', flex: 1),
        ];
        final rows = members
            .map(
              (member) => [
                Text(member.emailAddress, key: Key('email${members.indexOf(member)}')),
                Text(member.firstName),
                Text(member.status, key: Key('status${members.indexOf(member)}')),
                Text('${member.currentStep}'),
                IconButton(
                  key: Key('unsubscribe${members.indexOf(member)}'),
                  icon: const Icon(Icons.unsubscribe),
                  onPressed: member.status != 'ACTIVE'
                      ? null
                      : () async {
                          final shouldUnsubscribe = await confirmDialog(
                            context,
                            'Unsubscribe ${member.emailAddress}?',
                            'They will no longer receive emails from this sequence.',
                          );
                          if (shouldUnsubscribe == true) {
                            _emailSequenceBloc.add(
                              EmailSequenceMemberUnsubscribe(
                                emailSequenceId:
                                    widget.emailSequence.emailSequenceId,
                                enrollmentId: member.enrollmentId,
                              ),
                            );
                          }
                        },
                ),
              ],
            )
            .toList();
        return StyledDataTable(
          columns: columns,
          rows: rows,
          isLoading:
              state.memberStatus == EmailSequenceStatus.loading &&
              members.isEmpty,
        );
      },
    );
  }
}
