/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_sales.dart';

/// Returns widget mappings for the sales package
Map<String, GrowerpWidgetBuilder> getSalesWidgets() {
  return {
    'OpportunityList': (args) => OpportunityList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the sales package
List<WidgetMetadata> getSalesWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'OpportunityList',
      description: 'List of sales opportunities',
      iconName: 'trending_up',
      keywords: ['opportunity', 'sales', 'deal', 'lead', 'prospect'],
      builder: (args) => OpportunityList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'OpportunityDialog',
      description: 'Create or edit a sales opportunity. Pass opportunityId to '
          'edit an existing opportunity; omit it to create a new one.',
      iconName: 'trending_up',
      keywords: ['add opportunity', 'new opportunity', 'create opportunity', 'edit opportunity'],
      parameters: {'opportunityId': 'open this opportunity for editing; omit to create new'},
      builder: (args) {
        final id = (args?['opportunityId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return OpportunityDialog(Opportunity());
        return AsyncRecordDialog<Opportunity>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getOpportunity(opportunityId: id, limit: 1);
            return r.opportunities.isNotEmpty ? r.opportunities.first : null;
          },
          onLoaded: (o) => OpportunityDialog(o),
        );
      },
    ),
  ];
}
