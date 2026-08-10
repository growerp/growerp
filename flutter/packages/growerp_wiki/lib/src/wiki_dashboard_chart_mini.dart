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
import 'package:growerp_wiki/l10n/generated/wiki_localizations.dart';

/// Wiki tile: page counts per wiki space, with space/page totals.
/// Page counts need one call per space, so only the first [_maxSpaces] spaces
/// are queried — enough for the dashboard bars, and bounds the tile's cost.
class WikiDashboardChartMini extends StatelessWidget {
  const WikiDashboardChartMini({super.key});

  static const int _maxSpaces = 6;

  @override
  Widget build(BuildContext context) {
    final l = WikiLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('wikiDashboardMini'),
      emptyMessage: l.dashNoWikiSpaces,
      load: (rest) async {
        final spaces = (await rest.getWikiSpaces(limit: 100)).wikiSpaces;
        final queried = spaces.take(_maxSpaces).toList();
        final counts = await Future.wait(
          queried.map(
            (s) async => (await rest.getWikiPages(
              wikiSpaceId: s.wikiSpaceId ?? '',
              limit: 200,
            )).wikiPages.length,
          ),
        );
        final bySpace = <({String label, int count})>[
          for (int i = 0; i < queried.length; i++)
            (label: queried[i].wikiSpaceId ?? 'space', count: counts[i]),
        ]..sort((a, b) => b.count.compareTo(a.count));
        return (
          bars: <DashboardBar>[
            for (final e in bySpace.take(3))
              (label: e.label, count: e.count, color: null),
          ],
          counters: <DashboardCounter>[
            (label: l.dashSpaces, value: spaces.length),
            (label: l.dashPages, value: counts.fold<int>(0, (s, c) => s + c)),
          ],
        );
      },
    );
  }
}
