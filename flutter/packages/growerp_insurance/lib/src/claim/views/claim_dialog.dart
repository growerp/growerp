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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_insurance.dart';

/// Report a claim, or follow it up. Agency staff set the carrier's claim
/// number, the status and the amount paid; a client can only change its own
/// claim while it is still submitted.
class ClaimDialog extends StatefulWidget {
  final Claim claim;
  const ClaimDialog(this.claim, {super.key});
  @override
  ClaimDialogState createState() => ClaimDialogState();
}

class ClaimDialogState extends State<ClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountClaimedController = TextEditingController();
  final _claimNumberController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _commentsController = TextEditingController();
  Policy? _policy;
  DateTime? _incidentDate;
  ClaimStatus _status = ClaimStatus.submitted;
  late bool isNew;
  late bool isStaff;

  @override
  void initState() {
    super.initState();
    final claim = widget.claim;
    isNew = claim.claimId.isEmpty;
    final userGroup = context
        .read<AuthBloc>()
        .state
        .authenticate
        ?.user
        ?.userGroup;
    isStaff = userGroup != null && userGroup != UserGroup.other;
    _descriptionController.text = claim.description ?? '';
    _amountClaimedController.text = claim.amountClaimed?.toString() ?? '';
    _claimNumberController.text = claim.claimNumber ?? '';
    _amountPaidController.text = claim.amountPaid?.toString() ?? '';
    _commentsController.text = claim.comments ?? '';
    _incidentDate = claim.incidentDate?.toLocal();
    _status = claim.status ?? ClaimStatus.submitted;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('ClaimDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<ClaimBloc, ClaimState>(
        listener: (context, state) {
          switch (state.status) {
            case ClaimStatusBloc.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case ClaimStatusBloc.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.reportClaim
              : '${localizations.claim} ${widget.claim.pseudoId}',
          height: 650,
          width: isPhone ? 400 : 500,
          child: _showForm(localizations),
        ),
      ),
    );
  }

  Future<List<Policy>> _policies(String search) async {
    final result = await context.read<RestClient>().getPolicies(
      search: search.isEmpty ? null : search,
      limit: 5,
    );
    return result.policies;
  }

  Widget _showForm(InsuranceLocalizations localizations) {
    final isSubmitted =
        _status == ClaimStatus.submitted || _status == ClaimStatus.aiAssessed;
    // what the client reported can be changed until the agency handles it
    final canEditReport = isNew || isStaff || isSubmitted;
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('listView'),
        children: <Widget>[
          if (isNew)
            AutocompleteLabel<Policy>(
              key: const Key('policy'),
              label: localizations.policy,
              validator: (value) =>
                  value == null ? localizations.fieldRequired : null,
              optionsBuilder: (value) => _policies(value.text),
              displayStringForOption: (p) =>
                  '${p.policyNumber ?? p.pseudoId} '
                  '${p.policyType?.name ?? ''} ${p.insuredName ?? ''}',
              onSelected: (value) => setState(() => _policy = value),
            )
          else
            Text(
              '${localizations.policy}: '
              '${widget.claim.policyNumber ?? widget.claim.policyPseudoId ?? ''}'
              ' ${widget.claim.insuredName ?? ''}'
              ' (${widget.claim.carrierName ?? ''})',
              key: const Key('claimHeader'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 10),
          FormBuilderDateTimePicker(
            name: 'incidentDate',
            key: const Key('incidentDate'),
            initialValue: _incidentDate,
            enabled: canEditReport,
            inputType: InputType.date,
            lastDate: DateTime.now(),
            format: DateFormat('yyyy-MM-dd'),
            decoration: InputDecoration(
              labelText: localizations.incidentDate,
              hintText: 'yyyy-MM-dd',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onChanged: (value) => _incidentDate = value,
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('description'),
            decoration: InputDecoration(labelText: localizations.whatHappened),
            controller: _descriptionController,
            enabled: canEditReport,
            maxLines: 3,
            validator: (value) =>
                (value ?? '').isEmpty ? localizations.fieldRequired : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('amountClaimed'),
            decoration: InputDecoration(labelText: localizations.amountClaimed),
            controller: _amountClaimedController,
            enabled: canEditReport,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (!isNew && isStaff) ...[
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('claimNumber'),
              decoration: InputDecoration(labelText: localizations.claimNumber),
              controller: _claimNumberController,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ClaimStatus>(
              key: const Key('status'),
              decoration: InputDecoration(labelText: localizations.status),
              initialValue: _status,
              items: ClaimStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('amountPaid'),
              decoration: InputDecoration(labelText: localizations.amountPaid),
              controller: _amountPaidController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('comments'),
              decoration: InputDecoration(labelText: localizations.comments),
              controller: _commentsController,
              maxLines: 2,
            ),
          ],
          if (!isNew && !isStaff) ...[
            const SizedBox(height: 10),
            Text(
              '${localizations.status}: ${_status.name}',
              key: const Key('claimStatus'),
            ),
            if (widget.claim.amountPaid != null)
              Text(
                '${localizations.amountPaid}: ${widget.claim.amountPaid}',
                key: const Key('claimAmountPaid'),
              ),
          ],
          if (!isNew) ...[
            const SizedBox(height: 10),
            ClaimDetailsSection(
              claimId: widget.claim.claimId,
              isStaff: isStaff,
            ),
          ],
          const SizedBox(height: 20),
          if (canEditReport)
            ElevatedButton(
              key: const Key('update'),
              child: Text(
                isNew ? localizations.reportClaim : localizations.update,
              ),
              onPressed: () => _save(localizations),
            ),
          if (!isNew && isSubmitted) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('delete'),
              child: Text(localizations.delete),
              onPressed: () =>
                  context.read<ClaimBloc>().add(ClaimDelete(widget.claim)),
            ),
          ],
        ],
      ),
    );
  }

  void _save(InsuranceLocalizations localizations) {
    if (!_formKey.currentState!.validate()) return;
    if (_incidentDate == null) {
      HelperFunctions.showMessage(
        context,
        '${localizations.incidentDate}?',
        Colors.red,
      );
      return;
    }
    context.read<ClaimBloc>().add(
      ClaimUpdate(
        widget.claim.copyWith(
          policyId: _policy?.policyId ?? widget.claim.policyId,
          incidentDate: insuranceDateOnly(_incidentDate),
          description: _descriptionController.text,
          amountClaimed: Decimal.tryParse(_amountClaimedController.text),
          claimNumber: isStaff ? _claimNumberController.text : null,
          status: isStaff && !isNew ? _status : null,
          amountPaid: isStaff
              ? Decimal.tryParse(_amountPaidController.text)
              : null,
          comments: isStaff ? _commentsController.text : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountClaimedController.dispose();
    _claimNumberController.dispose();
    _amountPaidController.dispose();
    _commentsController.dispose();
    super.dispose();
  }
}
