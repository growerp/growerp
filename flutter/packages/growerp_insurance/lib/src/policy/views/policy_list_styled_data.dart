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

List<StyledColumn> getPolicyListColumns(
  BuildContext context,
  PolicyListMode mode,
) {
  final localizations = InsuranceLocalizations.of(context)!;
  if (isAPhone(context)) {
    return [StyledColumn(header: localizations.policies, flex: 6)];
  }
  return [
    const StyledColumn(header: 'Id', flex: 1),
    StyledColumn(header: localizations.policyNumber, flex: 2),
    StyledColumn(header: localizations.insured, flex: 3),
    StyledColumn(header: localizations.carrier, flex: 3),
    if (mode == PolicyListMode.commissions) ...[
      StyledColumn(header: localizations.commissionExpected, flex: 2),
      StyledColumn(header: localizations.commissionReceived, flex: 2),
    ] else ...[
      StyledColumn(header: localizations.policyType, flex: 2),
      StyledColumn(header: localizations.expirationDate, flex: 2),
      StyledColumn(header: localizations.status, flex: 2),
    ],
  ];
}

List<Widget> getPolicyListRow({
  required BuildContext context,
  required Policy policy,
  required int index,
  required PolicyListMode mode,
}) {
  final expires = policy.expirationDate?.toLocalizedDateOnly(context) ?? '';
  final expected = policy.commissionExpected?.toString() ?? '';
  final received = policy.commissionReceived?.toString() ?? '';
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
                policy.policyNumber ?? policy.pseudoId,
                key: Key('policyNumber$index'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text(' '),
              Flexible(
                child: Text(
                  policy.insuredName ?? '',
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
                Flexible(
                  child: Text(
                    policy.carrierName ?? '',
                    key: Key('carrier$index'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(' '),
                if (mode == PolicyListMode.commissions) ...[
                  Text(expected, key: Key('commissionExpected$index')),
                  const Text('/'),
                  Text(received, key: Key('commissionReceived$index')),
                ] else ...[
                  Text(expires, key: Key('expirationDate$index')),
                  const Text(' '),
                  Text(policy.status?.name ?? '', key: Key('status$index')),
                ],
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
      child: Text(policy.pseudoId, key: Key('id$index')),
    ),
    Text(policy.policyNumber ?? '', key: Key('policyNumber$index')),
    Text(policy.insuredName ?? '', key: Key('insured$index')),
    Text(policy.carrierName ?? '', key: Key('carrier$index')),
    if (mode == PolicyListMode.commissions) ...[
      Text(expected, key: Key('commissionExpected$index')),
      Text(received, key: Key('commissionReceived$index')),
    ] else ...[
      Text(policy.policyType?.name ?? '', key: Key('policyType$index')),
      Text(expires, key: Key('expirationDate$index')),
      Text(policy.status?.name ?? '', key: Key('status$index')),
    ],
  ];
}
