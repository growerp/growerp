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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/fin_doc_bloc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Returns column definitions for FinDoc list based on device type and docType
List<StyledColumn> getFinDocListColumns(
  BuildContext context, {
  required FinDocType docType,
  String? applicationId,
}) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  final isHotel = applicationId == 'AppHotel' || applicationId == 'AppRental';
  final isTransaction = docType == FinDocType.transaction;
  final isShipment = docType == FinDocType.shipment;

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrInfo, flex: 5),
      const StyledColumn(header: '', flex: 2), // Actions
    ];
  }

  List<StyledColumn> columns = [
    StyledColumn(
      header: localizations.tableHdrDocTypeId(
        docTypeLabel(localizations, docType),
      ),
      flex: 1,
    ),
  ];

  if (isTransaction) {
    columns.add(StyledColumn(header: localizations.type, flex: 1));
  }

  columns.add(
    StyledColumn(header: isHotel ? 'Reserv. Date' : 'Created', flex: 1),
  );
  columns.add(
    StyledColumn(header: localizations.tableHdrCustomerSupplier, flex: 2),
  );

  if (!isShipment) {
    columns.add(StyledColumn(header: localizations.tableHdrTotal, flex: 1));
  }

  // status labels are words, not numbers, so give them room to fit the chip
  columns.add(StyledColumn(header: localizations.status, flex: 2));
  columns.add(StyledColumn(header: localizations.tableHdrEmail, flex: 2));
  columns.add(const StyledColumn(header: '', flex: 1)); // Actions

  return columns;
}

/// Returns row data for FinDoc list
List<Widget> getFinDocListRow({
  required BuildContext context,
  required FinDoc finDoc,
  required int index,
  required Bloc bloc,
  String? applicationId,
}) {
  bool isPhone = isAPhone(context);
  final isHotel = applicationId == 'AppHotel' || applicationId == 'AppRental';
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  // Helper to get formatted date
  String getDateString() {
    if (isHotel && finDoc.items.isNotEmpty) {
      return finDoc.items[0].rentalFromDate?.toLocalizedDateOnly(context) ??
          '??';
    }
    return finDoc.placedDate?.toLocalizedDateOnly(context) ??
        finDoc.creationDate?.toLocalizedDateOnly(context) ??
        '??';
  }

  // Helper to get status display
  String getStatusString() {
    if (finDoc.status == null) return '?';
    if (isHotel && finDoc.docType == FinDocType.order) {
      return finDoc.status!.hotel;
    }
    return finDoc.status!.name;
  }

  // Helper to map status to StatusType
  StatusType getStatusType() {
    switch (finDoc.status) {
      case FinDocStatusVal.completed:
        return StatusType.success;
      case FinDocStatusVal.cancelled:
        return StatusType.danger;
      case FinDocStatusVal.approved:
        return StatusType.info;
      case FinDocStatusVal.created:
        return StatusType.warning;
      default:
        return StatusType.neutral;
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          finDoc.pseudoId?.lastChar(3) ?? '',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(finDoc.pseudoId ?? '', key: Key('id$index')),
              const SizedBox(width: 8),
              Text(
                getDateString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                key: const Key('date'),
              ),
            ],
          ),
          Text(
            finDoc.otherCompany?.name.truncate(25) ??
                finDoc.otherUser?.getName().truncate(25) ??
                '',
            key: Key("otherUser$index"),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              StatusChip(
                label: getStatusString(),
                type: getStatusType(),
                size: StatusChipSize.small,
                key: Key("status$index"),
              ),
              const SizedBox(width: 8),
              if (finDoc.docType != FinDocType.shipment &&
                  finDoc.docType != FinDocType.request)
                Text(
                  finDoc.grandTotal.currency(currencyId: currencyId),
                  key: Key("grandTotal$index"),
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
  } else {
    // ID
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(finDoc.pseudoId ?? '', key: Key('id$index')),
      ),
    );

    // Type (only for transactions)
    if (finDoc.docType == FinDocType.transaction) {
      cells.add(Text(finDoc.docSubType ?? ''));
    }

    // Date
    cells.add(Text(getDateString(), key: const Key('date')));

    // Customer/Supplier
    cells.add(
      Text(
        finDoc.otherCompany?.name.truncate(30) ??
            finDoc.otherUser?.getName().truncate(30) ??
            '',
        key: Key("otherUser$index"),
      ),
    );

    // Total (not for shipments)
    if (finDoc.docType != FinDocType.shipment) {
      cells.add(
        Text(
          finDoc.grandTotal.currency(currencyId: currencyId),
          textAlign: TextAlign.right,
          key: Key("grandTotal$index"),
        ),
      );
    }

    // Status
    cells.add(
      StatusChip(
        label: getStatusString(),
        type: getStatusType(),
        size: StatusChipSize.small,
        key: Key("status$index"),
      ),
    );

    // Email
    cells.add(
      Text(
        finDoc.otherCompany?.email ?? finDoc.otherUser?.email ?? '',
        key: Key("emailstatus$index"),
      ),
    );
  }

  // Actions
  cells.add(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (finDoc.docType == FinDocType.order ||
            finDoc.docType == FinDocType.invoice)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            key: Key('print$index'),
            icon: const Icon(Icons.print, size: 20),
            tooltip: 'PDF/Print ${finDoc.docType}',
            onPressed: () async {
              await context.push('/printer', extra: finDoc);
            },
          ),
        if (finDoc.docType == FinDocType.transaction && finDoc.isPosted != true)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            key: Key('isPosted$index'),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            tooltip: 'Post transaction',
            onPressed: () {
              bloc.add(FinDocUpdate(finDoc.copyWith(isPosted: true)));
            },
          ),
        if (finDoc.status != FinDocStatusVal.cancelled &&
            finDoc.status != FinDocStatusVal.completed)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_forever, size: 20),
            tooltip: 'remove item',
            onPressed: () async {
              bool? result = await confirmDialog(
                context,
                "delete ${finDoc.pseudoId}?",
                "cannot be undone!",
              );
              if (result == true) {
                bloc.add(
                  FinDocUpdate(
                    finDoc.copyWith(status: FinDocStatusVal.cancelled),
                  ),
                );
              }
            },
          ),
      ],
    ),
  );

  return cells;
}

String docTypeLabel(
  OrderAccountingLocalizations localizations,
  FinDocType docType,
) {
  switch (docType) {
    case FinDocType.request:
      return localizations.docTypeRequest;
    case FinDocType.order:
      return localizations.docTypeOrder;
    case FinDocType.invoice:
      return localizations.docTypeInvoice;
    case FinDocType.payment:
      return localizations.docTypePayment;
    case FinDocType.shipment:
      return localizations.docTypeShipment;
    case FinDocType.transaction:
      return localizations.docTypeTransaction;
    default:
      return '';
  }
}
