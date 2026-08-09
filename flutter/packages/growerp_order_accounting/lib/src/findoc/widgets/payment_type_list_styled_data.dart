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

import '../../accounting/accounting.dart';
import '../findoc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Returns column definitions for payment type list based on device type
List<StyledColumn> getPaymentTypeListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.paymentType, flex: 3),
      StyledColumn(header: localizations.tableHdrAccount, flex: 3),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    StyledColumn(header: localizations.paymentType, flex: 2),
    StyledColumn(header: localizations.tableHdrDirection, flex: 1),
    StyledColumn(header: localizations.tableHdrApplied, flex: 1),
    StyledColumn(header: localizations.accountCode, flex: 2),
    StyledColumn(header: localizations.accountName, flex: 3),
    const StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for payment type list
List<Widget> getPaymentTypeListRow({
  required BuildContext context,
  required PaymentType paymentType,
  required int index,
  required FinDocBloc finDocBloc,
  required GlAccountBloc glAccountBloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Avatar
  cells.add(
    CircleAvatar(
      radius: 16,
      child: Text(
        paymentType.paymentTypeName.length >= 5
            ? paymentType.paymentTypeName.substring(3, 5)
            : paymentType.paymentTypeName.isNotEmpty
            ? paymentType.paymentTypeName.substring(0, 2).toUpperCase()
            : '?',
        style: const TextStyle(fontSize: 12),
      ),
    ),
  );

  // Account Autocomplete widget
  Widget accountSelect = BlocBuilder<GlAccountBloc, GlAccountState>(
    builder: (context, state) {
      switch (state.status) {
        case GlAccountStatus.failure:
          return Text(OrderAccountingLocalizations.of(context)!.error);
        case GlAccountStatus.success:
          final initialText =
              '${paymentType.accountCode} ${paymentType.accountName}'.trim();
          final ptKey =
              '${paymentType.paymentTypeId}_${paymentType.isPayable ? 1 : 0}_${paymentType.isApplied ? 1 : 0}';
          return Autocomplete<GlAccount>(
            key: Key('glAccount_$ptKey'),
            initialValue: TextEditingValue(text: initialText),
            displayStringForOption: (GlAccount u) =>
                '${u.accountCode ?? ''} ${u.accountName ?? ''}',
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.toLowerCase();
              if (query.isEmpty) return glAccountBloc.state.glAccounts;
              return glAccountBloc.state.glAccounts.where((gl) {
                return '${gl.accountCode ?? ''} ${gl.accountName ?? ''}'
                    .toLowerCase()
                    .contains(query);
              }).toList();
            },
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    key: Key('glAccountField_$ptKey'),
                    controller: textController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                    style: const TextStyle(fontSize: 14),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                      maxWidth: 400,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, idx) {
                        final gl = options.elementAt(idx);
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${gl.accountCode ?? ''} ${gl.accountName ?? ''}',
                          ),
                          onTap: () => onSelected(gl),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (GlAccount newValue) {
              finDocBloc.add(
                FinDocUpdatePaymentType(
                  paymentType: paymentType.copyWith(
                    accountCode: newValue.accountCode!,
                    accountName: newValue.accountName!,
                  ),
                  update: true,
                ),
              );
            },
          );
        default:
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
      }
    },
  );

  if (isPhone) {
    // Combined payment type info
    cells.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            paymentType.paymentTypeName,
            key: Key('name$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                paymentType.isPayable ? 'Outgoing' : 'Incoming',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                paymentType.isApplied ? 'Applied' : 'Not Applied',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Account dropdown
    cells.add(accountSelect);
  } else {
    // Payment type name
    cells.add(Text(paymentType.paymentTypeName, key: Key('name$index')));

    // Direction
    cells.add(
      Text(
        paymentType.isPayable ? 'Outgoing' : 'Incoming',
        key: Key('direction$index'),
      ),
    );

    // Applied
    cells.add(
      Text(paymentType.isApplied ? 'Yes' : 'No', key: Key('applied$index')),
    );

    // Account code
    cells.add(Text(paymentType.accountCode, key: Key('accountCode$index')));

    // Account dropdown
    cells.add(accountSelect);
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        finDocBloc.add(
          FinDocUpdatePaymentType(paymentType: paymentType, delete: true),
        );
      },
    ),
  );

  return cells;
}
