/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';

/// Wiki tile: page counts per wiki space, with space/page totals.
/// Page counts need one call per space, so only the first [_maxSpaces] spaces
/// are queried — enough for the dashboard bars, and bounds the tile's cost.
class WikiDashboardChartMini extends StatelessWidget {
  const WikiDashboardChartMini({super.key});

  static const int _maxSpaces = 6;

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('wikiDashboardMini'),
    emptyMessage: 'No wiki spaces',
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
          (label: 'spaces', value: spaces.length),
          (label: 'pages', value: counts.fold<int>(0, (s, c) => s + c)),
        ],
      );
    },
  );
}
