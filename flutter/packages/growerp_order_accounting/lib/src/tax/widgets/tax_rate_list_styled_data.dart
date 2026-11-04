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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

List<StyledColumn> getTaxRateListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  return [
    StyledColumn(header: localizations.taxRateName, flex: 4),
    StyledColumn(header: localizations.taxRatePercentage, flex: 2),
    StyledColumn(header: localizations.taxRateCategory, flex: 3),
  ];
}

List<Widget> getTaxRateListRow({
  required BuildContext context,
  required TaxRate taxRate,
  required int index,
}) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  return [
    SizedBox(
      key: Key('item$index'),
      child: Text(taxRate.taxName ?? '', key: Key('name$index')),
    ),
    Text('${taxRate.taxPercentage ?? ''} %', key: Key('percentage$index')),
    Text(
      taxRate.categoryName ?? localizations.taxRateDefault,
      key: Key('category$index'),
    ),
  ];
}
