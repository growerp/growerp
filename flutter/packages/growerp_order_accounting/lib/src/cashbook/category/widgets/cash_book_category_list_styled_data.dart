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

import '../blocs/cash_book_category_bloc.dart';

List<StyledColumn> getCashBookCategoryListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  return [
    StyledColumn(header: localizations.cashBookCategoryName, flex: 5),
    StyledColumn(header: localizations.cashBookCategoryInUse, flex: 2),
  ];
}

List<Widget> getCashBookCategoryListRow({
  required BuildContext context,
  required GlAccount category,
  required int index,
  required CashBookCategoryBloc bloc,
}) {
  return [
    SizedBox(
      key: Key('item$index'),
      child: Text(category.accountName ?? '', key: Key('name$index')),
    ),
    // the switch handles its own tap, the rest of the row opens the dialog
    Switch(
      key: Key('inUse$index'),
      value: category.isUsed ?? false,
      onChanged: (value) =>
          bloc.add(CashBookCategoryUpdate(category, isUsed: value)),
    ),
  ];
}
