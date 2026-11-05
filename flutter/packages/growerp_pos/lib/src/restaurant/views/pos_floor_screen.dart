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
import '../../shift/views/pos_shift_gate.dart';
import '../blocs/pos_floor_bloc.dart';
import '../blocs/pos_tab_bloc.dart';
import 'pos_live_refresh.dart';
import 'pos_tab_screen.dart';
import 'pos_table_dialog.dart';

/// Size of one place on the floor.
const double _cell = 130;

/// The tables where they stand. A tap opens the tab of the table. An admin can
/// switch to editing: add tables and drag them to their place.
class PosFloorScreen extends StatefulWidget {
  const PosFloorScreen({super.key});

  @override
  PosFloorScreenState createState() => PosFloorScreenState();
}

class PosFloorScreenState extends State<PosFloorScreen> with PosLiveRefresh {
  late PosFloorBloc _bloc;
  bool _editing = false;
  final Map<String, Offset> _dragged = {};

  @override
  void initState() {
    super.initState();
    _bloc = context.read<PosFloorBloc>()..add(const PosFloorFetch());
    startRefresh();
  }

  @override
  void onRefresh() => _bloc.add(const PosFloorFetch());

  @override
  void dispose() {
    stopRefresh();
    super.dispose();
  }

  bool get _isAdmin =>
      context.read<AuthBloc>().state.authenticate?.user?.userGroup ==
      UserGroup.admin;

  Future<void> _openTable(PosTable table, String terminalName) async {
    final tabBloc = context.read<PosTabBloc>();
    tabBloc.add(PosTabOpen(tabId: table.tabId, tableAssetId: table.assetId));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosTabScreen(terminalName: terminalName),
      ),
    );
    _bloc.add(const PosFloorFetch());
  }

  Future<void> _editTable(PosTable? table, List<PosTable> tables) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: PosTableDialog(table, place: tables.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return PosShiftGate(
      needsShift: _isAdmin,
      builder: (context, terminalName) =>
          BlocConsumer<PosFloorBloc, PosFloorState>(
            listener: (context, state) {
              if (state.status == PosFloorStatus.failure) {
                HelperFunctions.showMessage(context, state.message, Colors.red);
              }
            },
            builder: (context, state) {
              if (state.status == PosFloorStatus.initial) {
                return const Center(child: LoadingIndicator());
              }
              final width = state.tables.fold<int>(
                5,
                (max, t) => (t.x ?? 0) + 1 > max ? (t.x ?? 0) + 1 : max,
              );
              final height = state.tables.fold<int>(
                4,
                (max, t) => (t.y ?? 0) + 1 > max ? (t.y ?? 0) + 1 : max,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isAdmin)
                    PosTillBar(
                      terminalName: terminalName,
                      currencyId: _currencyId(context),
                    ),
                  if (_isAdmin)
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Text(localizations.editFloor),
                        Switch(
                          key: const Key('posFloorEdit'),
                          value: _editing,
                          onChanged: (value) =>
                              setState(() => _editing = value),
                        ),
                        if (_editing)
                          TextButton.icon(
                            key: const Key('posTableAdd'),
                            icon: const Icon(Icons.add),
                            label: Text(localizations.newTable),
                            onPressed: () => _editTable(null, state.tables),
                          ),
                      ],
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: state.tables.isEmpty
                        ? Center(
                            key: const Key('posFloorEmpty'),
                            child: Text(localizations.noTables),
                          )
                        : SingleChildScrollView(
                            key: const Key('posFloorScroll'),
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                key: const Key('PosFloorScreen'),
                                width: width * _cell,
                                height: height * _cell,
                                child: Stack(
                                  children: [
                                    for (final (index, table)
                                        in state.tables.indexed)
                                      _table(
                                        table,
                                        index,
                                        state.tables,
                                        terminalName,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
    );
  }

  String _currencyId(BuildContext context) =>
      context
          .read<AuthBloc>()
          .state
          .authenticate
          ?.company
          ?.currency
          ?.currencyId ??
      'USD';

  Widget _table(
    PosTable table,
    int index,
    List<PosTable> tables,
    String terminalName,
  ) {
    final color = switch (table.status) {
      'ready' => Colors.green.shade300,
      'occupied' => Colors.orange.shade300,
      _ => Theme.of(context).colorScheme.surfaceContainerHighest,
    };
    final place =
        _dragged[table.assetId] ??
        Offset((table.x ?? 0) * _cell, (table.y ?? 0) * _cell);
    return Positioned(
      left: place.dx,
      top: place.dy,
      child: GestureDetector(
        key: Key('posTable$index'),
        onTap: () => _editing
            ? _editTable(table, tables)
            : _openTable(table, terminalName),
        onPanUpdate: !_editing
            ? null
            : (details) => setState(
                () => _dragged[table.assetId!] = place + details.delta,
              ),
        onPanEnd: !_editing
            ? null
            : (_) {
                final end = _dragged.remove(table.assetId);
                if (end == null) return;
                _bloc.add(
                  PosTableSave(
                    table.copyWith(
                      x: (end.dx / _cell).round().clamp(0, 50),
                      y: (end.dy / _cell).round().clamp(0, 50),
                    ),
                  ),
                );
              },
        child: Container(
          width: _cell - 12,
          height: _cell - 12,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: table.shape == 'round'
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: table.shape == 'round'
                ? null
                : BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                table.tableName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (table.grandTotal != null)
                Text(
                  table.grandTotal.currency(currencyId: _currencyId(context)),
                  key: Key('posTableTotal$index'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
