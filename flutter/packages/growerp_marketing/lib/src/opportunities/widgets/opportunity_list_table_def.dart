/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';
import '../bloc/opportunity_bloc.dart';

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    Opportunity item, int index,
    {dynamic extra}) {
  final localizations = MarketingLocalizations.of(context)!;
  List<TableRowContent> rowContent = [];
  bool isPhone = isAPhone(context);
  if (isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrShortId,
        width: 15,
        value: CircleAvatar(
          minRadius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            item.pseudoId.lastChar(3),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        )));
  }
  rowContent.add(TableRowContent(
      name: localizations.tableHdrId,
      width: isPhone ? 15 : 10,
      value: Text(item.pseudoId, key: Key('id$index'))));
  rowContent.add(TableRowContent(
      name: localizations.tableHdrName,
      width: isPhone ? 35 : 15,
      value: Text("${item.opportunityName}", key: Key('name$index'))));
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrAmount,
        width: 5,
        value: Text(item.estAmount.toString(),
            key: Key('estAmount$index'), textAlign: TextAlign.center)));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrProbability,
        width: 5,
        value: Text(item.estProbability.toString(),
            key: Key('estProbability$index'), textAlign: TextAlign.center)));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrLead,
        width: 15,
        value: Text(
          (item.leadUser != null
              ? "${item.leadUser!.firstName} "
                  "${item.leadUser!.lastName},\n "
                  "${item.leadUser!.company!.name}"
              : ""),
          key: Key('lead$index'),
        )));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrLeadEmail,
        width: 10,
        value: Text(
          item.leadUser != null ? item.leadUser!.email ?? '' : "",
          key: Key('leadEmail$index'),
        )));
  }
  if (!isPhone) {
    rowContent.add(TableRowContent(
        name: localizations.tableHdrStage,
        width: 8,
        value: Text("${item.stageId}",
            key: Key('stageId$index'), textAlign: TextAlign.center)));
  }
  rowContent.add(TableRowContent(
      name: localizations.tableHdrNextStep,
      width: 17,
      value: Text(item.nextStep != null ? "${item.nextStep}" : "",
          key: Key('nextStep$index'), textAlign: TextAlign.center)));
  rowContent.add(TableRowContent(
      width: isPhone ? 5 : 5,
      name: localizations.tableHdrDelete,
      value: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          tooltip: localizations.removeItemTooltip,
          onPressed: () async {
            bool? result = await confirmDialog(
                context,
                localizations.deleteItemConfirm(item.pseudoId),
                localizations.cannotBeUndone);
            if (result == true) {
              bloc.add(OpportunityDelete(item));
            }
          })));

  return TableData(rowHeight: isPhone ? 40 : 40, rowContent: rowContent);
}

// general settings
var padding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
