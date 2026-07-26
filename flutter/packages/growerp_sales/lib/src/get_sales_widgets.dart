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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_sales.dart';

/// Returns widget mappings for the sales package
Map<String, GrowerpWidgetBuilder> getSalesWidgets() {
  return {
    'OpportunityList': (args) => OpportunityList(key: getKeyFromArgs(args)),
    'OpportunityPipeline': (args) =>
        OpportunityPipeline(key: getKeyFromArgs(args)),
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
      widgetName: 'OpportunityPipeline',
      description: 'Kanban pipeline board of opportunities by stage '
          'with a funnel summary',
      iconName: 'view_kanban',
      keywords: ['pipeline', 'kanban', 'funnel', 'stage', 'forecast'],
      builder: (args) => OpportunityPipeline(key: getKeyFromArgs(args)),
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
