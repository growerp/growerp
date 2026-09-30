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

import '../../../growerp_insurance.dart';

/// Client portal: the policies of the logged in client (the backend only
/// returns the policies insured by the client or its company) and its
/// claims, where a new claim is reported.
class MyPoliciesView extends StatefulWidget {
  const MyPoliciesView({super.key});

  @override
  MyPoliciesViewState createState() => MyPoliciesViewState();
}

class MyPoliciesViewState extends State<MyPoliciesView> {
  @override
  void initState() {
    super.initState();
    context.read<PolicyBloc>().add(const PoliciesFetch(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    return Column(
      key: const Key('MyPoliciesView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  localizations.myPolicies,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                key: const Key('askAssistant'),
                icon: const Icon(Icons.support_agent),
                label: Text(localizations.assistant),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const InsuranceAssistantDialog(),
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<PolicyBloc, PolicyState>(
          builder: (context, state) {
            // renewed and cancelled policies are history for the client
            final policies = state.policies
                .where(
                  (p) =>
                      p.status != PolicyStatus.renewed &&
                      p.status != PolicyStatus.cancelled,
                )
                .toList();
            if (policies.isEmpty) {
              if (state.status == PolicyStatusBloc.loading ||
                  state.status == PolicyStatusBloc.initial) {
                return const LoadingIndicator();
              }
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  localizations.noPolicies,
                  key: const Key('noPolicies'),
                ),
              );
            }
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView(
                key: const Key('myPolicyList'),
                shrinkWrap: true,
                children: policies
                    .asMap()
                    .entries
                    .map((e) => _policyCard(localizations, e.key, e.value))
                    .toList(),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Text(
            localizations.myClaims,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Expanded(child: ClaimList(portal: true)),
      ],
    );
  }

  Widget _policyCard(
    InsuranceLocalizations localizations,
    int index,
    Policy policy,
  ) {
    final from = policy.effectiveDate?.toLocalizedDateOnly(context) ?? '';
    final thru = policy.expirationDate?.toLocalizedDateOnly(context) ?? '';
    return Card(
      key: Key('myPolicy$index'),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        onTap: () => _showCard(policy),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${policy.policyType?.name ?? ''} '
                      '${policy.policyNumber ?? policy.pseudoId}'
                      '${(policy.vehiclePlate ?? '').isEmpty ? '' : ' · ${policy.vehiclePlate}'}',
                      key: Key('myPolicyTitle$index'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: Key('myPolicyCard$index'),
                    tooltip: localizations.showCard,
                    icon: const Icon(Icons.qr_code_2),
                    onPressed: () => _showCard(policy),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 20,
                runSpacing: 5,
                children: [
                  Text(
                    '${localizations.carrier}: ${policy.carrierName ?? ''}',
                    key: Key('myPolicyCarrier$index'),
                  ),
                  Text('$from - $thru', key: Key('myPolicyPeriod$index')),
                  Text(
                    '${localizations.status}: ${policy.status?.name ?? ''}',
                    key: Key('myPolicyStatus$index'),
                  ),
                  if (policy.premiumAmount != null)
                    Text(
                      '${localizations.premium}: ${policy.premiumAmount} '
                      '${policy.premiumFrequency?.name ?? ''}',
                      key: Key('myPolicyPremium$index'),
                    ),
                ],
              ),
              ...(policy.coverages ?? <PolicyCoverage>[]).map(
                (coverage) => Text(
                  '${coverage.coverageName ?? ''}: '
                  '${localizations.limit} ${coverage.limitAmount ?? '-'}, '
                  '${localizations.deductible} '
                  '${coverage.deductibleAmount ?? '-'}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCard(Policy policy) => showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => BlocProvider.value(
      value: context.read<PolicyBloc>(),
      child: PolicyCardDialog(policy),
    ),
  );
}
