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

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../../growerp_insurance.dart';

/// Guided first notice of loss for the client: what happened, when and
/// where, photos along a checklist, then review. The photos are triaged by
/// AI in the background for the adjuster, who decides.
class ClaimWizardDialog extends StatefulWidget {
  const ClaimWizardDialog({super.key, this.policies = const []});

  /// the client's policies a claim can be made on
  final List<Policy> policies;

  @override
  ClaimWizardDialogState createState() => ClaimWizardDialogState();
}

class ClaimWizardDialogState extends State<ClaimWizardDialog> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  int _step = 0;
  Policy? _policy;
  IncidentType? _incidentType;
  DateTime? _incidentDate;
  bool _consent = false;

  /// photo per checklist slot; extra photos after the slots
  final Map<int, Uint8List> _photos = {};
  static const _slotCount = 4;

  @override
  void initState() {
    super.initState();
    if (widget.policies.length == 1) _policy = widget.policies.first;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    return Dialog(
      key: const Key('ClaimWizardDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<ClaimBloc, ClaimState>(
        listener: (context, state) {
          switch (state.status) {
            case ClaimStatusBloc.success:
              HelperFunctions.showMessage(
                context,
                localizations.claimSubmitted,
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
          title: localizations.reportClaim,
          height: 720,
          width: 460,
          child: ListView(
            key: const Key('listView'),
            children: [
              Text(
                localizations.wizardStep(_step + 1, 4),
                key: const Key('wizardStep'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              LinearProgressIndicator(value: (_step + 1) / 4),
              const SizedBox(height: 12),
              ...switch (_step) {
                0 => _whatStep(localizations),
                1 => _whenStep(localizations),
                2 => _photoStep(localizations),
                _ => _reviewStep(localizations),
              },
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      key: const Key('wizardBack'),
                      onPressed: () => setState(() => _step--),
                      child: Text(localizations.back),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    ElevatedButton(
                      key: const Key('wizardNext'),
                      onPressed: _canContinue
                          ? () => setState(() => _step++)
                          : null,
                      child: Text(localizations.next),
                    )
                  else
                    ElevatedButton(
                      key: const Key('wizardSubmit'),
                      onPressed: _consent ? _submit : null,
                      child: Text(localizations.submitClaim),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    0 => _policy != null && _incidentType != null,
    1 => _incidentDate != null && _descriptionController.text.trim().isNotEmpty,
    _ => true, // photos help, but a claim without them is still a claim
  };

  List<Widget> _whatStep(InsuranceLocalizations localizations) => [
    DropdownButtonFormField<Policy>(
      key: const Key('wizardPolicy'),
      decoration: InputDecoration(labelText: localizations.policy),
      initialValue: _policy,
      items: widget.policies
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(
                '${p.policyType?.name ?? ''} '
                '${p.vehiclePlate ?? p.policyNumber ?? p.pseudoId}',
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _policy = value),
    ),
    const SizedBox(height: 16),
    Text(localizations.whatHappened),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncidentType.values
          .map(
            (type) => ChoiceChip(
              key: Key('incidentType${type.index}'),
              label: Text(incidentTypeLabel(localizations, type)),
              selected: _incidentType == type,
              onSelected: (_) => setState(() => _incidentType = type),
            ),
          )
          .toList(),
    ),
    if (_incidentType == IncidentType.injury) ...[
      const SizedBox(height: 12),
      Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(localizations.injuryFirst, key: const Key('injuryFirst')),
        ),
      ),
    ],
  ];

  List<Widget> _whenStep(InsuranceLocalizations localizations) => [
    FormBuilderDateTimePicker(
      name: 'incidentDate',
      key: const Key('incidentDate'),
      initialValue: _incidentDate,
      inputType: InputType.date,
      lastDate: DateTime.now(),
      format: DateFormat('yyyy-MM-dd'),
      decoration: InputDecoration(
        labelText: localizations.incidentDate,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onChanged: (value) => setState(() => _incidentDate = value),
    ),
    const SizedBox(height: 10),
    TextFormField(
      key: const Key('incidentLocation'),
      decoration: InputDecoration(labelText: localizations.incidentLocation),
      controller: _locationController,
    ),
    const SizedBox(height: 10),
    TextFormField(
      key: const Key('description'),
      decoration: InputDecoration(
        labelText: localizations.describeIncident,
        alignLabelWithHint: true,
      ),
      controller: _descriptionController,
      maxLines: 4,
      onChanged: (_) => setState(() {}),
    ),
  ];

  List<Widget> _photoStep(InsuranceLocalizations localizations) {
    final slots = [
      localizations.photoPlate,
      localizations.photoOverview,
      localizations.photoDamage,
      localizations.photoOther,
    ];
    return [
      Text(localizations.photoIntro),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < _photos.length + 1 || i < _slotCount; i++)
            _photoTile(i, i < _slotCount ? slots[i] : localizations.photoExtra),
        ],
      ),
    ];
  }

  Widget _photoTile(int slot, String label) {
    final photo = _photos[slot];
    return InkWell(
      key: Key('photo$slot'),
      onTap: () => _pick(slot),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: photo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 32),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(label, textAlign: TextAlign.center),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(photo, fit: BoxFit.cover),
                  ),
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pick(int slot) async {
    final file = await HelperFunctions.pickImage();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // big enough for the assessment, small enough for a phone connection
    final decoded = img.decodeImage(bytes);
    final Uint8List data = decoded == null
        ? bytes
        : img.encodeJpg(
            decoded.width > 1280
                ? img.copyResize(decoded, width: 1280)
                : decoded,
            quality: 80,
          );
    setState(() => _photos[slot] = data);
  }

  List<Widget> _reviewStep(InsuranceLocalizations localizations) => [
    Text(
      '${_policy?.policyType?.name ?? ''} '
      '${_policy?.vehiclePlate ?? _policy?.policyNumber ?? ''}',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(incidentTypeLabel(localizations, _incidentType ?? IncidentType.other)),
    Text(
      '${_incidentDate?.toLocalizedDateOnly(context) ?? ''} '
      '${_locationController.text}',
    ),
    Text(_descriptionController.text),
    Text(
      localizations.photoCount(_photos.length),
      key: const Key('photoCount'),
    ),
    const SizedBox(height: 10),
    TextFormField(
      key: const Key('amountClaimed'),
      decoration: InputDecoration(
        labelText: localizations.amountClaimedOptional,
      ),
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    ),
    const SizedBox(height: 10),
    CheckboxListTile(
      key: const Key('consent'),
      value: _consent,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(localizations.claimConsent),
      onChanged: (value) => setState(() => _consent = value ?? false),
    ),
  ];

  void _submit() {
    final labels = [
      'licence plate',
      'overview',
      'damage close-up',
      'other vehicle or scene',
    ];
    final keys = _photos.keys.toList()..sort();
    context.read<ClaimBloc>().add(
      ClaimUpdate(
        Claim(
          policyId: _policy!.policyId,
          incidentType: _incidentType,
          incidentDate: insuranceDateOnly(_incidentDate),
          incidentLocation: _locationController.text,
          description: _descriptionController.text,
          amountClaimed: Decimal.tryParse(_amountController.text),
          photos: keys
              .map(
                (slot) => ClaimPhoto(
                  description: slot < labels.length ? labels[slot] : 'extra',
                  image: _photos[slot],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

/// Plain-language label of an incident type in the user's language.
String incidentTypeLabel(InsuranceLocalizations l, IncidentType type) =>
    switch (type) {
      IncidentType.collision => l.incidentCollision,
      IncidentType.singleVehicle => l.incidentSingleVehicle,
      IncidentType.parked => l.incidentParked,
      IncidentType.injury => l.incidentInjury,
      IncidentType.flood => l.incidentFlood,
      IncidentType.theft => l.incidentTheft,
      IncidentType.glass => l.incidentGlass,
      IncidentType.other => l.incidentOther,
    };
