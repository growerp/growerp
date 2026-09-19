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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late EmailSequenceBloc _emailSequenceBloc;

  @override
  void initState() {
    super.initState();
    _emailSequenceBloc = context.read<EmailSequenceBloc>()
      ..add(EmailSequenceMembersFetch(widget.emailSequence.emailSequenceId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocListener<EmailSequenceBloc, EmailSequenceState>(
      listenWhen: (previous, current) =>
          previous.memberStatus != current.memberStatus,
      listener: (context, state) {
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
          child: _dialogContent(isPhone),
        ),
      ),
    );
  }

  Widget _dialogContent(bool isPhone) {
    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search by email or name...',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _emailSequenceBloc.add(
              EmailSequenceMembersFetch(
                widget.emailSequence.emailSequenceId,
                searchString: value,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Stack(
            children: [
              _memberTable(),
              Positioned(
                right: isPhone ? 20 : 50,
                bottom: 20,
                child: FloatingActionButton(
                  key: const Key('addNewMember'),
                  onPressed: () async {
                    await showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) => BlocProvider.value(
                        value: _emailSequenceBloc,
                        child: _AddMemberDialog(
                          emailSequenceId: widget.emailSequence.emailSequenceId,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Add member',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
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

/// Small modal form to manually add one member to a sequence, opened from
/// the members dialog's FAB.
class _AddMemberDialog extends StatefulWidget {
  final String emailSequenceId;
  const _AddMemberDialog({required this.emailSequenceId});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmailSequenceBloc, EmailSequenceState>(
      listenWhen: (previous, current) =>
          previous.memberStatus != current.memberStatus,
      listener: (context, state) {
        if (state.memberStatus == EmailSequenceStatus.success) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        key: const Key('AddEmailSequenceMemberDialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: 'Add member',
          height: 280,
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('memberEmail'),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Email required' : null,
                ),
                TextFormField(
                  key: const Key('memberFirstName'),
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  key: const Key('addMember'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<EmailSequenceBloc>().add(
                        EmailSequenceMemberAdd(
                          emailSequenceId: widget.emailSequenceId,
                          emailAddress: _emailController.text,
                          firstName: _firstNameController.text,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
