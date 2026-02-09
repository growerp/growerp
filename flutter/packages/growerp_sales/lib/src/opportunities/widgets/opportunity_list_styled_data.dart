/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/l10n/generated/sales_localizations.dart';

import '../bloc/opportunity_bloc.dart';

/// Returns column definitions for opportunity list based on device type
List<StyledColumn> getOpportunityListColumns(
  BuildContext context,
  SalesLocalizations localizations,
) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrId, flex: 1),
      StyledColumn(header: localizations.tableHdrName, flex: 3),
      StyledColumn(header: localizations.tableHdrNextStep, flex: 2),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.tableHdrId, flex: 1),
    StyledColumn(header: localizations.tableHdrName, flex: 2),
    StyledColumn(header: localizations.tableHdrAmount, flex: 1),
    StyledColumn(header: localizations.tableHdrProbability, flex: 1),
    StyledColumn(header: localizations.tableHdrLead, flex: 2),
    StyledColumn(header: localizations.tableHdrLeadEmail, flex: 2),
    StyledColumn(header: localizations.tableHdrStage, flex: 1),
    StyledColumn(header: localizations.tableHdrNextStep, flex: 2),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for opportunity list
List<Widget> getOpportunityListRow({
  required BuildContext context,
  required Opportunity opportunity,
  required int index,
  required OpportunityBloc bloc,
  required SalesLocalizations localizations,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    final shouldDelete = await confirmDialog(
      context,
      localizations.deleteItemConfirm(opportunity.pseudoId),
      localizations.cannotBeUndone,
    );
    if (shouldDelete == true) {
      bloc.add(OpportunityDelete(opportunity));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Avatar
    cells.add(
      CircleAvatar(
        minRadius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          opportunity.pseudoId.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    );

    // ID
    cells.add(Text(opportunity.pseudoId, key: Key('id$index')));

    // Name
    cells.add(
      Text(
        opportunity.opportunityName ?? '',
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Next Step
    cells.add(
      Text(
        opportunity.nextStep ?? '',
        key: Key('nextStep$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  } else {
    // ID
    cells.add(Text(opportunity.pseudoId, key: Key('id$index')));

    // Name
    cells.add(
      Text(
        opportunity.opportunityName ?? '',
        key: Key('name$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Est Amount
    cells.add(
      Text(
        opportunity.estAmount?.toString() ?? '-',
        key: Key('estAmount$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Est Probability
    cells.add(
      Text(
        '${opportunity.estProbability ?? 0}%',
        key: Key('estProbability$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Lead
    cells.add(
      Text(
        opportunity.leadUser != null
            ? '${opportunity.leadUser!.firstName ?? ''} '
                  '${opportunity.leadUser!.lastName ?? ''}'
            : '-',
        key: Key('lead$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Lead Email
    cells.add(
      Text(
        opportunity.leadUser?.email ?? '-',
        key: Key('leadEmail$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Stage
    cells.add(_buildStageChip(context, opportunity.stageId));

    // Next Step
    cells.add(
      Text(
        opportunity.nextStep ?? '-',
        key: Key('nextStep$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Delete action
  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: localizations.removeItemTooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: confirmDelete,
    ),
  );

  return cells;
}

Widget _buildStageChip(BuildContext context, String? stageId) {
  Color color;
  switch (stageId) {
    case 'Prospecting':
      color = Colors.blue;
      break;
    case 'Qualification':
      color = Colors.orange;
      break;
    case 'Proposal':
      color = Colors.purple;
      break;
    case 'Negotiation':
      color = Colors.amber;
      break;
    case 'Closed Won':
      color = Colors.green;
      break;
    case 'Closed Lost':
      color = Colors.red;
      break;
    default:
      color = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      stageId ?? '-',
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center,
    ),
  );
}
