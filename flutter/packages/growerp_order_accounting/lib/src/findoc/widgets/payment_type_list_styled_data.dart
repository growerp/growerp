/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting/accounting.dart';
import '../findoc.dart';

/// Returns column definitions for payment type list based on device type
List<StyledColumn> getPaymentTypeListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      const StyledColumn(header: 'Payment Type', flex: 3),
      const StyledColumn(header: 'Account', flex: 3),
      const StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    const StyledColumn(header: 'Payment Type', flex: 2),
    const StyledColumn(header: 'Direction', flex: 1),
    const StyledColumn(header: 'Applied', flex: 1),
    const StyledColumn(header: 'Account Code', flex: 2),
    const StyledColumn(header: 'Account Name', flex: 3),
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
          return const Text('Error');
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
