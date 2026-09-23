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
import 'adk_catalog_promotion_view.dart';
import 'adk_suggest_function_panel.dart';

/// Support App View: "Agent Catalog" — the two admin-facing halves of catalog
/// curation, combined behind one menu entry:
/// - **Promotion**: review tenant-nominated agents and promote them into the
///   shared "_NA_" catalog (`AdkCatalogPromotionView`).
/// - **Suggestion**: run the same "Suggest a function" feasibility check
///   tenants use, on behalf of a named tenant, to preview or troubleshoot a
///   suggestion before advising them (`AdkSuggestFunctionPanel`).
class AdkAgentCatalogView extends StatelessWidget {
  const AdkAgentCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(key: Key('agentCatalogPromotionTab'), text: 'Promotion'),
              Tab(key: Key('agentCatalogSuggestionTab'), text: 'Suggestion'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AdkCatalogPromotionView(),
                AdkSuggestFunctionPanel(showOwnerField: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
