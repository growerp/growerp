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
import 'package:growerp_models/growerp_models.dart';

/// Website reads of one content piece, per platform. Adapted posts link to the
/// website with utm tags; a visit counts as "landed" on arrival and as "read"
/// once the page was visible long enough and scrolled, which bots, link
/// previews and mail privacy proxies never do.
class ContentReadsView extends StatelessWidget {
  const ContentReadsView({super.key, required this.stats});
  final ContentReadStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final hint = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return GroupingDecorator(
      labelText: 'Website reads',
      child: s == null || s.landings == 0
          ? Text(
              'No visits from this piece\'s links yet. Posts with a Target '
              'URL on your website count landings and reads here.',
              key: const Key('noContentReads'),
              style: hint,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landed ${s.landings} (${s.uniqueVisitors} unique) · '
                  'read ${s.reads} (${s.readRate}%) · '
                  'avg ${s.avgDwellSeconds}s on page',
                  key: const Key('contentReadTotals'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Landed counts every visit from a tagged link, link previews '
                  'and scanners included; read only counts visitors who stayed '
                  'and scrolled.',
                  style: hint,
                ),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {0: FlexColumnWidth(2)},
                  children: [
                    const TableRow(children: [
                      Text('Platform',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Landed',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Reads',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Avg s',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    ...s.platforms.map((p) => TableRow(
                          key: ValueKey('platform${p.platform}'),
                          children: [
                            Text(p.platform.isEmpty ? '?' : p.platform),
                            Text('${p.landings}'),
                            Text('${p.reads}'),
                            Text('${p.avgDwellSeconds}'),
                          ],
                        )),
                  ],
                ),
              ],
            ),
    );
  }
}
