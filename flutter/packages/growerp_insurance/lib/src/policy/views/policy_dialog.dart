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

/// Enter or change a policy with its coverages, renew or delete it.
class PolicyDialog extends StatefulWidget {
  final Policy policy;
  const PolicyDialog(this.policy, {super.key});
  @override
  PolicyDialogState createState() => PolicyDialogState();
}

class _CoverageRow {
  _CoverageRow(PolicyCoverage coverage)
    : name = TextEditingController(text: coverage.coverageName ?? ''),
      limit = TextEditingController(
        text: coverage.limitAmount?.toString() ?? '',
      ),
      deductible = TextEditingController(
        text: coverage.deductibleAmount?.toString() ?? '',
      );
  final TextEditingController name;
  final TextEditingController limit;
  final TextEditingController deductible;

  PolicyCoverage get coverage => PolicyCoverage(
    coverageName: name.text,
    limitAmount: Decimal.tryParse(limit.text),
    deductibleAmount: Decimal.tryParse(deductible.text),
  );

  void dispose() {
    name.dispose();
    limit.dispose();
    deductible.dispose();
  }
}

class PolicyDialogState extends State<PolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _policyNumberController = TextEditingController();
  final _premiumController = TextEditingController();
  final _commissionRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleDescriptionController = TextEditingController();
  final List<_CoverageRow> _coverages = [];
  CompanyUser? _insured;
  CompanyUser? _carrier;
  PolicyType _policyType = PolicyType.other;
  PolicyStatus _status = PolicyStatus.active;
  PremiumFrequency _frequency = PremiumFrequency.annual;
  DateTime? _effectiveDate;
  DateTime? _expirationDate;
  late bool isNew;
  late PolicyBloc _policyBloc;

  @override
  void initState() {
    super.initState();
    final policy = widget.policy;
    _policyBloc = context.read<PolicyBloc>();
    isNew = policy.policyId.isEmpty;
    _policyNumberController.text = policy.policyNumber ?? '';
    _premiumController.text = policy.premiumAmount?.toString() ?? '';
    _commissionRateController.text = policy.commissionRate?.toString() ?? '';
    _descriptionController.text = policy.description ?? '';
    _vehiclePlateController.text = policy.vehiclePlate ?? '';
    _vehicleDescriptionController.text = policy.vehicleDescription ?? '';
    if (policy.insuredPartyId != null) {
      _insured = CompanyUser(
        partyId: policy.insuredPartyId,
        name: policy.insuredName,
      );
    }
    if (policy.carrierPartyId != null) {
      _carrier = CompanyUser(
        partyId: policy.carrierPartyId,
        name: policy.carrierName,
      );
    }
    _policyType = policy.policyType ?? PolicyType.other;
    _status = policy.status ?? PolicyStatus.active;
    _frequency = policy.premiumFrequency ?? PremiumFrequency.annual;
    _effectiveDate = policy.effectiveDate?.toLocal();
    _expirationDate = policy.expirationDate?.toLocal();
    for (final coverage in policy.coverages ?? <PolicyCoverage>[]) {
      _coverages.add(_CoverageRow(coverage));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('PolicyDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PolicyBloc, PolicyState>(
        listener: (context, state) {
          switch (state.status) {
            case PolicyStatusBloc.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case PolicyStatusBloc.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newPolicy
              : '${localizations.policy} ${widget.policy.pseudoId}',
          height: 700,
          width: isPhone ? 400 : 600,
          child: _showForm(localizations),
        ),
      ),
    );
  }

  Future<List<CompanyUser>> _companyUsers(Role role, String search) async {
    final result = await context.read<RestClient>().getCompanyUser(
      role: role,
      searchString: search,
      limit: 5,
    );
    return result.companiesUsers;
  }

  Widget _dateField(
    String key,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return FormBuilderDateTimePicker(
      name: key,
      key: Key(key),
      initialValue: value,
      inputType: InputType.date,
      format: DateFormat('yyyy-MM-dd'),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'yyyy-MM-dd',
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onChanged: onChanged,
    );
  }

  Widget _showForm(InsuranceLocalizations localizations) {
    final canRenew =
        !isNew &&
        (widget.policy.status == PolicyStatus.active ||
            widget.policy.status == PolicyStatus.renewalDue ||
            widget.policy.status == PolicyStatus.lapsed);
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('listView'),
        children: <Widget>[
          TextFormField(
            key: const Key('policyNumber'),
            decoration: InputDecoration(labelText: localizations.policyNumber),
            controller: _policyNumberController,
          ),
          const SizedBox(height: 10),
          AutocompleteLabel<CompanyUser>(
            key: const Key('insured'),
            label: localizations.insured,
            initialValue: _insured,
            validator: (value) =>
                value == null ? localizations.fieldRequired : null,
            optionsBuilder: (value) => _companyUsers(Role.customer, value.text),
            displayStringForOption: (u) => u.name ?? '',
            onSelected: (value) => setState(() => _insured = value),
          ),
          const SizedBox(height: 10),
          AutocompleteLabel<CompanyUser>(
            key: const Key('carrier'),
            label: localizations.carrier,
            initialValue: _carrier,
            validator: (value) =>
                value == null ? localizations.fieldRequired : null,
            optionsBuilder: (value) => _companyUsers(Role.supplier, value.text),
            displayStringForOption: (u) => u.name ?? '',
            onSelected: (value) => setState(() => _carrier = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<PolicyType>(
            key: const Key('policyType'),
            decoration: InputDecoration(labelText: localizations.policyType),
            initialValue: _policyType,
            items: PolicyType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onChanged: (value) =>
                setState(() => _policyType = value ?? PolicyType.other),
          ),
          if (!isNew) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<PolicyStatus>(
              key: const Key('status'),
              decoration: InputDecoration(labelText: localizations.status),
              initialValue: _status,
              items: PolicyStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
          ],
          const SizedBox(height: 10),
          _dateField(
            'effectiveDate',
            localizations.effectiveDate,
            _effectiveDate,
            (value) => _effectiveDate = value,
          ),
          const SizedBox(height: 10),
          _dateField(
            'expirationDate',
            localizations.expirationDate,
            _expirationDate,
            (value) => _expirationDate = value,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('premium'),
                  decoration: InputDecoration(labelText: localizations.premium),
                  controller: _premiumController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<PremiumFrequency>(
                  key: const Key('premiumFrequency'),
                  decoration: InputDecoration(
                    labelText: localizations.premiumFrequency,
                  ),
                  initialValue: _frequency,
                  items: PremiumFrequency.values
                      .map(
                        (f) => DropdownMenuItem(value: f, child: Text(f.name)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _frequency = value ?? _frequency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('commissionRate'),
            decoration: InputDecoration(
              labelText: localizations.commissionRate,
            ),
            controller: _commissionRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('description'),
            decoration: InputDecoration(labelText: localizations.description),
            controller: _descriptionController,
            maxLines: 2,
          ),
          if (_policyType == PolicyType.auto ||
              _policyType == PolicyType.motorCompulsory) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('vehiclePlate'),
                    decoration: InputDecoration(
                      labelText: localizations.vehiclePlate,
                    ),
                    controller: _vehiclePlateController,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('vehicleDescription'),
                    decoration: InputDecoration(
                      labelText: localizations.vehicleDescription,
                    ),
                    controller: _vehicleDescriptionController,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            localizations.coverages,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._coverages.asMap().entries.map(
            (entry) => _coverageRow(localizations, entry.key, entry.value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('addCoverage'),
              icon: const Icon(Icons.add),
              label: Text(localizations.addCoverage),
              onPressed: () => setState(
                () => _coverages.add(_CoverageRow(PolicyCoverage())),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('update'),
            child: Text(isNew ? localizations.add : localizations.update),
            onPressed: () => _save(localizations),
          ),
          if (canRenew) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('renew'),
              child: Text(localizations.renew),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  localizations.renew,
                  localizations.renewConfirm,
                );
                if (ok == true) {
                  _policyBloc.add(
                    PolicyRenew(
                      widget.policy.copyWith(
                        premiumAmount: Decimal.tryParse(
                          _premiumController.text,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          if (!isNew) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('delete'),
              child: Text(localizations.delete),
              onPressed: () => _policyBloc.add(PolicyDelete(widget.policy)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverageRow(
    InsuranceLocalizations localizations,
    int index,
    _CoverageRow row,
  ) {
    return Row(
      key: Key('coverage$index'),
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            key: Key('coverageName$index'),
            decoration: InputDecoration(labelText: localizations.coverage),
            controller: row.name,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: Key('coverageLimit$index'),
            decoration: InputDecoration(labelText: localizations.limit),
            controller: row.limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: Key('coverageDeductible$index'),
            decoration: InputDecoration(labelText: localizations.deductible),
            controller: row.deductible,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        IconButton(
          key: Key('removeCoverage$index'),
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _coverages.removeAt(index).dispose()),
        ),
      ],
    );
  }

  void _save(InsuranceLocalizations localizations) {
    if (!_formKey.currentState!.validate()) return;
    if (_effectiveDate == null || _expirationDate == null) {
      HelperFunctions.showMessage(
        context,
        '${localizations.effectiveDate}/${localizations.expirationDate}?',
        Colors.red,
      );
      return;
    }
    _policyBloc.add(
      PolicyUpdate(
        widget.policy.copyWith(
          policyNumber: _policyNumberController.text,
          insuredPartyId: _insured?.partyId,
          carrierPartyId: _carrier?.partyId,
          policyType: _policyType,
          status: isNew ? null : _status,
          effectiveDate: insuranceDateOnly(_effectiveDate),
          expirationDate: insuranceDateOnly(_expirationDate),
          premiumAmount: Decimal.tryParse(_premiumController.text),
          premiumFrequency: _frequency,
          commissionRate: Decimal.tryParse(_commissionRateController.text),
          description: _descriptionController.text,
          vehiclePlate: _vehiclePlateController.text,
          vehicleDescription: _vehicleDescriptionController.text,
          coverages: _coverages
              .map((row) => row.coverage)
              .where((c) => (c.coverageName ?? '').isNotEmpty)
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _policyNumberController.dispose();
    _premiumController.dispose();
    _commissionRateController.dispose();
    _descriptionController.dispose();
    _vehiclePlateController.dispose();
    _vehicleDescriptionController.dispose();
    for (final row in _coverages) {
      row.dispose();
    }
    super.dispose();
  }
}
