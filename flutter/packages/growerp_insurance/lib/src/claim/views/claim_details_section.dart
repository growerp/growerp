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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_insurance.dart';

/// What an existing claim shows besides its fields: the status timeline with
/// what each step means, the photos, and for agency staff the AI triage of
/// the photos (advice), for the client only the extra evidence asked for.
class ClaimDetailsSection extends StatefulWidget {
  const ClaimDetailsSection({
    super.key,
    required this.claimId,
    required this.isStaff,
  });
  final String claimId;
  final bool isStaff;

  @override
  State<ClaimDetailsSection> createState() => _ClaimDetailsSectionState();
}

class _ClaimDetailsSectionState extends State<ClaimDetailsSection> {
  Claim? _claim;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // photos and timeline only come with a claim read by id
    try {
      final result = await context.read<RestClient>().getClaims(
        claimId: widget.claimId,
      );
      if (mounted && result.claims.isNotEmpty) {
        setState(() => _claim = result.claims.first);
      }
    } catch (_) {
      // the dialog still shows the claim fields without the details
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final claim = _claim;
    if (claim == null) return const LoadingIndicator();
    return Column(
      key: const Key('claimDetails'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (claim.incidentType != null || (claim.incidentLocation ?? '') != '')
          Text(
            '${claim.incidentType == null ? '' : incidentTypeLabel(localizations, claim.incidentType!)}'
            '${(claim.incidentLocation ?? '').isEmpty ? '' : ' · ${claim.incidentLocation}'}',
            key: const Key('claimIncident'),
          ),
        const SizedBox(height: 10),
        _timeline(localizations, claim),
        if (!widget.isStaff && (claim.missingEvidence ?? []).isNotEmpty)
          _missingEvidence(localizations, claim),
        if ((claim.photos ?? []).isNotEmpty) _photos(localizations, claim),
        if (widget.isStaff && (claim.aiAssessment ?? '').isNotEmpty)
          _aiPanel(localizations, claim),
      ],
    );
  }

  Widget _timeline(InsuranceLocalizations localizations, Claim claim) {
    final history = claim.statusHistory ?? [];
    return Column(
      key: const Key('claimTimeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.claimProgress,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        for (final (index, change) in history.indexed)
          ListTile(
            key: Key('timeline$index'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              index == history.length - 1
                  ? Icons.radio_button_checked
                  : Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(change.status?.name ?? ''),
            subtitle: Text(
              '${change.changedDate?.toLocalizedDateOnly(context) ?? ''} · '
              '${statusExplanation(localizations, change.status)}',
            ),
          ),
      ],
    );
  }

  Widget _missingEvidence(InsuranceLocalizations localizations, Claim claim) =>
      Card(
        key: const Key('missingEvidence'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.missingEvidenceTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...claim.missingEvidence!.map((e) => Text('• $e')),
            ],
          ),
        ),
      );

  Widget _photos(InsuranceLocalizations localizations, Claim claim) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10),
      Text(
        localizations.photos,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      SizedBox(
        height: 110,
        child: ListView(
          key: const Key('claimPhotos'),
          scrollDirection: Axis.horizontal,
          children: [
            for (final photo in claim.photos!)
              if (photo.image != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.memory(photo.image!),
                        ),
                      ),
                    ),
                    child: Tooltip(
                      message: photo.description ?? '',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          photo.image!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ],
  );

  Widget _aiPanel(InsuranceLocalizations localizations, Claim claim) {
    Map<String, dynamic> ai;
    try {
      ai = jsonDecode(claim.aiAssessment!) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }
    List<String> list(String key) =>
        ((ai[key] as List?) ?? []).map((e) => e.toString()).toList();
    final parts = ((ai['damagedParts'] as List?) ?? [])
        .map((p) => '${p['part']} (${p['severity']})')
        .join(', ');
    Widget row(String label, String? value) => (value ?? '').isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          );
    return Card(
      key: const Key('aiAssessment'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 6),
                Text(
                  localizations.aiAssessment,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              localizations.aiAdvisoryNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            row('', ai['summary']?.toString()),
            row(localizations.severity, ai['overallSeverity']?.toString()),
            row(localizations.drivable, ai['drivable']?.toString()),
            row(
              localizations.plateCheck,
              '${ai['plateInPhotos'] ?? '-'} (${ai['plateMatchesPolicy'] ?? '?'})',
            ),
            row(localizations.photos, parts),
            row(localizations.consistency, list('consistency').join('; ')),
            row(
              localizations.suggestedNextStep,
              ai['suggestedNextStep']?.toString().replaceAll('_', ' '),
            ),
            row(localizations.reviewFlags, list('reviewFlags').join('; ')),
            row(
              localizations.missingEvidenceTitle,
              list('missingEvidence').join('; '),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a claim status means for the client, in plain words.
String statusExplanation(InsuranceLocalizations l, ClaimStatus? status) =>
    switch (status) {
      ClaimStatus.submitted => l.statusExplainSubmitted,
      ClaimStatus.aiAssessed => l.statusExplainAiAssessed,
      ClaimStatus.inReview => l.statusExplainInReview,
      ClaimStatus.filed => l.statusExplainFiled,
      ClaimStatus.approved => l.statusExplainApproved,
      ClaimStatus.denied => l.statusExplainDenied,
      ClaimStatus.paid => l.statusExplainPaid,
      ClaimStatus.closed => l.statusExplainClosed,
      null => '',
    };
