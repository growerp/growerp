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
import 'package:qr_flutter/qr_flutter.dart';

import '../../../growerp_insurance.dart';

/// Digital policy card of the client portal: always-at-hand proof of
/// insurance. The QR code opens the public verify page on the server, so
/// police or a garage see the live status, not a copy that can be outdated.
class PolicyCardDialog extends StatefulWidget {
  const PolicyCardDialog(this.policy, {super.key});
  final Policy policy;

  @override
  PolicyCardDialogState createState() => PolicyCardDialogState();
}

class PolicyCardDialogState extends State<PolicyCardDialog> {
  late Policy _policy;
  bool _requesting = false;
  bool _explaining = false;

  @override
  void initState() {
    super.initState();
    _policy = widget.policy;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    return Dialog(
      key: const Key('PolicyCardDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PolicyBloc, PolicyState>(
        listener: (context, state) {
          if (!_requesting) return;
          switch (state.status) {
            case PolicyStatusBloc.success:
              _requesting = false;
              setState(() {
                _policy = state.policies.firstWhere(
                  (p) => p.policyId == _policy.policyId,
                  orElse: () => _policy,
                );
              });
              HelperFunctions.showMessage(
                context,
                localizations.renewalRequestSent,
                Colors.green,
              );
            case PolicyStatusBloc.failure:
              _requesting = false;
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: localizations.digitalCard,
          height: 720,
          width: 420,
          child: ListView(
            key: const Key('listView'),
            children: [_card(localizations)],
          ),
        ),
      ),
    );
  }

  Future<void> _explain() async {
    setState(() => _explaining = true);
    try {
      var result = await context.read<RestClient>().explainPolicy(
        policyId: _policy.policyId,
      );
      if (result is String) result = jsonDecode(result);
      if (!mounted) return;
      setState(
        () => _policy = _policy.copyWith(
          plainSummary: result['plainSummary'] as String?,
        ),
      );
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  Widget _card(InsuranceLocalizations localizations) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final thru = _policy.expirationDate;
    final valid =
        (_policy.status == PolicyStatus.active ||
            _policy.status == PolicyStatus.renewalDue) &&
        thru != null &&
        thru.isAfter(now);
    final statusColor = !valid
        ? theme.colorScheme.error
        : _policy.status == PolicyStatus.renewalDue
        ? Colors.orange.shade800
        : Colors.green.shade700;
    final thruText = thru?.toLocalizedDateOnly(context) ?? '';
    final canRequest =
        _policy.renewalRequestedDate == null &&
        (_policy.status == PolicyStatus.renewalDue ||
            _policy.status == PolicyStatus.lapsed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('cardStatus'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            valid
                ? localizations.validUntil(thruText)
                : localizations.notValid(thruText),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        if ((_policy.vehiclePlate ?? '').isNotEmpty)
          Text(
            _policy.vehiclePlate!,
            key: const Key('cardPlate'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        if ((_policy.vehicleDescription ?? '').isNotEmpty)
          Text(_policy.vehicleDescription!, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          '${_policy.policyType?.name ?? ''} · '
          '${_policy.policyNumber ?? _policy.pseudoId}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${localizations.carrier}: ${_policy.carrierName ?? ''}',
          textAlign: TextAlign.center,
        ),
        Text(
          '${_policy.effectiveDate?.toLocalizedDateOnly(context) ?? ''}'
          ' - $thruText',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if ((_policy.verificationUrl ?? '').isNotEmpty) ...[
          Center(
            child: Container(
              color: Colors.white, // QR scanners need a light background
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                key: const Key('cardQr'),
                data: _policy.verificationUrl!,
                size: 200,
              ),
            ),
          ),
          Text(
            localizations.qrHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        if (_policy.renewalRequestedDate != null)
          Text(
            localizations.renewalRequested(
              _policy.renewalRequestedDate!.toLocalizedDateOnly(context),
            ),
            key: const Key('renewalRequested'),
            textAlign: TextAlign.center,
          ),
        if (canRequest)
          OutlinedButton(
            key: const Key('requestRenewal'),
            onPressed: () {
              _requesting = true;
              context.read<PolicyBloc>().add(
                PolicyRenewalRequest(policyId: _policy.policyId),
              );
            },
            child: Text(localizations.requestRenewal),
          ),
        const SizedBox(height: 12),
        Text(
          localizations.coverages,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...(_policy.coverages ?? <PolicyCoverage>[]).map(
          (coverage) => Text(
            '${coverage.coverageName ?? ''}: '
            '${localizations.limit} ${coverage.limitAmount ?? '-'}, '
            '${localizations.deductible} ${coverage.deductibleAmount ?? '-'}',
          ),
        ),
        const SizedBox(height: 12),
        if ((_policy.plainSummary ?? '').isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _policy.plainSummary!,
                key: const Key('plainSummary'),
              ),
            ),
          )
        else if (_explaining)
          const LoadingIndicator()
        else
          OutlinedButton.icon(
            key: const Key('explainPolicy'),
            icon: const Icon(Icons.auto_awesome),
            label: Text(localizations.explainPolicy),
            onPressed: _explain,
          ),
      ],
    );
  }
}
