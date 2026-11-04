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

import '../../../l10n/generated/pos_localizations.dart';
import '../../checkout/blocs/pos_sale_bloc.dart';
import '../blocs/pos_tab_bloc.dart';

/// Split the bill equally or by item, then pay all shares at once. Pops with the
/// sale.
class PosSplitDialog extends StatefulWidget {
  const PosSplitDialog({super.key, required this.terminalName});
  final String terminalName;

  @override
  PosSplitDialogState createState() => PosSplitDialogState();
}

class PosSplitDialogState extends State<PosSplitDialog> {
  bool _byItem = false;
  int _ways = 2;
  final Map<String, int> _assigned = {};
  final Map<int, String> _methods = {};

  List<PosTabLine> _lines(PosTab tab) =>
      tab.lines.where((line) => line.kitchenStatus != 'Voided').toList();

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Dialog(
      key: const Key('PosSplitDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PosSaleBloc, PosSaleState>(
        listener: (context, state) {
          if (state.status == PosSaleStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosSaleStatus.success) {
            Navigator.of(context).pop(state.sale);
          }
        },
        child: BlocConsumer<PosTabBloc, PosTabState>(
          listener: (context, state) {
            if (state.status == PosTabStatus.failure) {
              HelperFunctions.showMessage(context, state.message, Colors.red);
            }
          },
          builder: (context, state) {
            final tab = state.tab!;
            final currencyId = tab.currencyId ?? 'USD';
            return popUp(
              context: context,
              title: localizations.splitBill,
              height: 560,
              width: 400,
              child: ListView(
                key: const Key('listView'),
                children: [
                  SegmentedButton<bool>(
                    key: const Key('posSplitMode'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(
                          localizations.splitEqual,
                          key: const Key('posSplitEqual'),
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          localizations.splitByItem,
                          key: const Key('posSplitItems'),
                        ),
                      ),
                    ],
                    selected: {_byItem},
                    onSelectionChanged: (selection) =>
                        setState(() => _byItem = selection.first),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: const Key('posSplitMinus'),
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _ways > 2
                            ? () => setState(() => _ways--)
                            : null,
                      ),
                      Text('$_ways', key: const Key('posSplitWays')),
                      IconButton(
                        key: const Key('posSplitPlus'),
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _ways++),
                      ),
                    ],
                  ),
                  if (_byItem)
                    for (final (index, line) in _lines(tab).indexed)
                      ListTile(
                        key: Key('posSplitLine$index'),
                        dense: true,
                        title: Text(line.description ?? ''),
                        trailing: DropdownButton<int>(
                          key: Key('posSplitShare$index'),
                          value: (_assigned[line.orderItemSeqId] ?? 1) > _ways
                              ? 1
                              : _assigned[line.orderItemSeqId] ?? 1,
                          items: [
                            for (var share = 1; share <= _ways; share++)
                              DropdownMenuItem(
                                value: share,
                                child: Text('$share'),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _assigned[line.orderItemSeqId!] = value!,
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('posSplitCalculate'),
                    onPressed: () => context.read<PosTabBloc>().add(
                      _byItem
                          ? PosTabSplit(
                              assignments: _lines(tab)
                                  .map(
                                    (line) => PosSplitAssignment(
                                      orderItemSeqId: line.orderItemSeqId,
                                      splitNo:
                                          _assigned[line.orderItemSeqId] ?? 1,
                                    ),
                                  )
                                  .toList(),
                            )
                          : PosTabSplit(ways: _ways),
                    ),
                    child: Text(localizations.calculate),
                  ),
                  if (state.status == PosTabStatus.split) ...[
                    for (final (index, share) in state.shares.indexed)
                      ListTile(
                        key: Key('posShare$index'),
                        dense: true,
                        title: Text(
                          share.amount.currency(currencyId: currencyId),
                          key: Key('posShareAmount$index'),
                        ),
                        trailing: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: 'PiCash',
                              label: Text(localizations.cash),
                            ),
                            ButtonSegment(
                              value: 'PiCreditCard',
                              label: Text(localizations.card),
                            ),
                          ],
                          selected: {_methods[index] ?? 'PiCash'},
                          onSelectionChanged: (selection) =>
                              setState(() => _methods[index] = selection.first),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      key: const Key('posSplitPay'),
                      onPressed: () => context.read<PosSaleBloc>().add(
                        PosSaleSettle(
                          tabId: tab.tabId!,
                          terminalName: widget.terminalName,
                          tenders: [
                            for (final (index, share) in state.shares.indexed)
                              PosTender(
                                method: _methods[index] ?? 'PiCash',
                                amount: share.amount,
                              ),
                          ],
                        ),
                      ),
                      child: Text(localizations.pay),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
