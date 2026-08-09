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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/liner_panel_bloc.dart';
import 'package:growerp_manuf_liner/l10n/generated/manuf_liner_localizations.dart';

List<StyledColumn> getLinerPanelListColumns(BuildContext context) {
  final localizations = ManufLinerLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      StyledColumn(header: localizations.tableHdrQcNumber, flex: 1),
      StyledColumn(header: localizations.tableHdrInfo, flex: 4),
      const StyledColumn(header: '', flex: 1),
    ];
  }
  return [
    StyledColumn(header: localizations.tableHdrQcNumber, flex: 1),
    StyledColumn(header: localizations.tableHdrPanelName, flex: 2),
    StyledColumn(header: localizations.tableHdrLiner, flex: 2),
    StyledColumn(header: localizations.tableHdrWFt, flex: 1),
    StyledColumn(header: localizations.tableHdrLFt, flex: 1),
    StyledColumn(header: localizations.tableHdrSqft, flex: 1),
    StyledColumn(header: localizations.tableHdrPasses, flex: 1),
    StyledColumn(header: localizations.tableHdrWtLb, flex: 1),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getLinerPanelListRow({
  required BuildContext context,
  required LinerPanel linerPanel,
  required int index,
  required Bloc bloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  if (isPhone) {
    cells.add(Text(linerPanel.qcNum, key: Key('qcNum$index')));
    cells.add(
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            linerPanel.panelName ?? linerPanel.linerName ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '${linerPanel.panelWidth ?? ''}ft × ${linerPanel.panelLength ?? ''}ft'
            ' | ${linerPanel.panelSqft ?? ''} sqft',
            key: Key('info$index'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    // wrap so the row's 'item$index' tap-key exists on desktop too (tests tap it
    // to open the row)
    cells.add(
      SizedBox(
        key: Key('item$index'),
        child: Text(linerPanel.qcNum, key: Key('qcNum$index')),
      ),
    );
    cells.add(Text(linerPanel.panelName ?? '', key: Key('panelName$index')));
    cells.add(Text(linerPanel.linerName ?? '', key: Key('linerName$index')));
    cells.add(
      Text(
        linerPanel.panelWidth?.toString() ?? '',
        key: Key('panelWidth$index'),
        textAlign: TextAlign.right,
      ),
    );
    cells.add(
      Text(
        linerPanel.panelLength?.toString() ?? '',
        key: Key('panelLength$index'),
        textAlign: TextAlign.right,
      ),
    );
    cells.add(
      Text(
        linerPanel.panelSqft?.toString() ?? '',
        key: Key('panelSqft$index'),
        textAlign: TextAlign.right,
      ),
    );
    cells.add(
      Text(
        linerPanel.passes?.toString() ?? '',
        key: Key('passes$index'),
        textAlign: TextAlign.right,
      ),
    );
    cells.add(
      Text(
        linerPanel.weight?.toString() ?? '',
        key: Key('weight$index'),
        textAlign: TextAlign.right,
      ),
    );
  }

  cells.add(
    IconButton(
      key: Key('delete$index'),
      icon: const Icon(Icons.delete_forever),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        bool? result = await confirmDialog(
          context,
          "delete panel ${linerPanel.qcNum}?",
          "cannot be undone!",
        );
        if (result == true) {
          bloc.add(LinerPanelDelete(linerPanel));
        }
      },
    ),
  );

  return cells;
}
