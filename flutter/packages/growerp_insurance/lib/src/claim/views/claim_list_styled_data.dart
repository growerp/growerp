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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_insurance.dart';

List<StyledColumn> getClaimListColumns(
  BuildContext context, {
  required bool portal,
}) {
  final localizations = InsuranceLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [StyledColumn(header: localizations.claims, flex: 6)];
  }
  return [
    const StyledColumn(header: 'Id', flex: 1),
    StyledColumn(header: localizations.policy, flex: 2),
    if (!portal) StyledColumn(header: localizations.insured, flex: 3),
    StyledColumn(header: localizations.incidentDate, flex: 2),
    StyledColumn(header: localizations.amountClaimed, flex: 2),
    StyledColumn(header: localizations.status, flex: 2),
  ];
}

List<Widget> getClaimListRow({
  required BuildContext context,
  required Claim claim,
  required int index,
  required bool portal,
}) {
  final incident = claim.incidentDate?.toLocalizedDateOnly(context) ?? '';
  final policy = claim.policyNumber ?? claim.policyPseudoId ?? '';
  if (isAPhone(context)) {
    return [
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                claim.pseudoId,
                key: Key('id$index'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text(' '),
              Text(policy, key: Key('policy$index')),
              const Text(' '),
              if (!portal)
                Flexible(
                  child: Text(
                    claim.insuredName ?? '',
                    key: Key('insured$index'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Row(
              children: [
                Text(incident, key: Key('incidentDate$index')),
                const Text(' '),
                Text(
                  claim.amountClaimed?.toString() ?? '',
                  key: Key('amountClaimed$index'),
                ),
                const Text(' '),
                Text(claim.status?.name ?? '', key: Key('status$index')),
              ],
            ),
          ),
        ],
      ),
    ];
  }
  return [
    SizedBox(
      key: Key('item$index'),
      child: Text(claim.pseudoId, key: Key('id$index')),
    ),
    Text(policy, key: Key('policy$index')),
    if (!portal) Text(claim.insuredName ?? '', key: Key('insured$index')),
    Text(incident, key: Key('incidentDate$index')),
    Text(
      claim.amountClaimed?.toString() ?? '',
      key: Key('amountClaimed$index'),
    ),
    Text(claim.status?.name ?? '', key: Key('status$index')),
  ];
}
