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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../../checkout/blocs/pos_catalog_bloc.dart';
import '../../checkout/blocs/pos_sale_bloc.dart';
import '../../checkout/views/pos_catalog_pane.dart';
import '../../checkout/views/pos_receipt_dialog.dart';
import '../../checkout/views/pos_tender_dialog.dart';
import '../blocs/pos_floor_bloc.dart';
import '../blocs/pos_tab_bloc.dart';
import 'pos_modifier_dialog.dart';
import 'pos_split_dialog.dart';

/// The bill of a table: the menu on one side, the lines on the other.
class PosTabScreen extends StatefulWidget {
  const PosTabScreen({super.key, required this.terminalName});
  final String terminalName;

  @override
  PosTabScreenState createState() => PosTabScreenState();
}

class PosTabScreenState extends State<PosTabScreen> {
  Future<void> _add(PosCatalogItem item) async {
    final tabBloc = context.read<PosTabBloc>();
    final catalog = context.read<PosCatalogBloc>().state;
    final groups = catalog.modifierGroups
        .where((group) => group.productIds.contains(item.productId))
        .toList();
    if (groups.isEmpty) {
      tabBloc.add(PosTabAddLine(item.productId!));
      return;
    }
    final choice = await showDialog<PosModifierChoice>(
      context: context,
      builder: (_) => PosModifierDialog(
        productName: item.productName ?? '',
        groups: groups,
        currencyId: catalog.currencyId ?? 'USD',
      ),
    );
    if (choice == null) return;
    tabBloc.add(
      PosTabAddLine(
        item.productId!,
        modifierIds: choice.modifierIds,
        note: choice.note.isEmpty ? null : choice.note,
      ),
    );
  }

  Future<void> _void(PosTabLine line) async {
    final bloc = context.read<PosTabBloc>();
    if (line.kitchenStatus == 'New') {
      bloc.add(PosTabVoidLine(line.orderItemSeqId!));
      return;
    }
    final localizations = PosLocalizations.of(context)!;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        key: const Key('PosVoidDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: localizations.voidLine,
          height: 220,
          width: 340,
          child: Column(
            children: [
              TextField(
                key: const Key('posVoidReason'),
                controller: controller,
                decoration: InputDecoration(labelText: localizations.reason),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('posVoidConfirm'),
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(localizations.voidLine),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (reason == null) return;
    bloc.add(PosTabVoidLine(line.orderItemSeqId!, reason: reason));
  }

  Future<void> _move() async {
    final bloc = context.read<PosTabBloc>();
    final localizations = PosLocalizations.of(context)!;
    final free = context
        .read<PosFloorBloc>()
        .state
        .tables
        .where((table) => table.status == 'free')
        .toList();
    final table = await showDialog<PosTable>(
      context: context,
      builder: (context) => Dialog(
        key: const Key('PosMoveDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: localizations.moveTab,
          height: 360,
          width: 320,
          child: ListView(
            key: const Key('listView'),
            children: [
              for (final (index, table) in free.indexed)
                ListTile(
                  key: Key('posMoveTable$index'),
                  title: Text(table.tableName ?? ''),
                  onTap: () => Navigator.of(context).pop(table),
                ),
            ],
          ),
        ),
      ),
    );
    if (table != null) bloc.add(PosTabMove(table.assetId!));
  }

  Future<void> _finished(PosSale? sale) async {
    if (sale == null || !mounted) return;
    final navigator = Navigator.of(context);
    context.read<PosSaleBloc>().add(const PosSaleReset());
    await showDialog(context: context, builder: (_) => PosReceiptDialog(sale));
    if (navigator.mounted) navigator.pop();
  }

  Future<void> _pay(PosTab tab) async {
    final saleBloc = context.read<PosSaleBloc>();
    final sale = await showDialog<PosSale>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: saleBloc,
        child: PosTenderDialog(
          lines: const [],
          grandTotal: tab.grandTotal ?? Decimal.zero,
          currencyId: tab.currencyId ?? 'USD',
          terminalName: widget.terminalName,
          tabId: tab.tabId,
        ),
      ),
    );
    await _finished(sale);
  }

  Future<void> _split() async {
    final saleBloc = context.read<PosSaleBloc>();
    final tabBloc = context.read<PosTabBloc>();
    final sale = await showDialog<PosSale>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: saleBloc),
          BlocProvider.value(value: tabBloc),
        ],
        child: PosSplitDialog(terminalName: widget.terminalName),
      ),
    );
    await _finished(sale);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return BlocConsumer<PosTabBloc, PosTabState>(
      listener: (context, state) {
        if (state.status == PosTabStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == PosTabStatus.closed) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final tab = state.tab;
        return Scaffold(
          key: const Key('PosTabScreen'),
          appBar: AppBar(
            title: Text(tab?.tableName ?? localizations.bar),
            actions: [
              IconButton(
                key: const Key('posMove'),
                icon: const Icon(Icons.move_up),
                tooltip: localizations.moveTab,
                onPressed: tab == null ? null : _move,
              ),
            ],
          ),
          body: tab == null
              ? const Center(child: LoadingIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final menu = PosCatalogPane(onItem: _add);
                    if (constraints.maxWidth >= 700) {
                      return Row(
                        children: [
                          Expanded(child: menu),
                          const VerticalDivider(width: 1),
                          SizedBox(width: 360, child: _bill(tab, state)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(flex: 3, child: menu),
                        const Divider(height: 1),
                        Expanded(flex: 2, child: _bill(tab, state)),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _bill(PosTab tab, PosTabState state) {
    final localizations = PosLocalizations.of(context)!;
    final bloc = context.read<PosTabBloc>();
    final currencyId = tab.currencyId ?? 'USD';
    final hasNew = tab.lines.any((line) => line.kitchenStatus == 'New');
    final total = tab.grandTotal ?? Decimal.zero;
    final ready = state.status != PosTabStatus.loading;
    return Column(
      children: [
        Expanded(
          child: tab.lines.isEmpty
              ? Center(
                  key: const Key('posTabEmpty'),
                  child: Text(localizations.cartEmpty),
                )
              : ListView.builder(
                  key: const Key('posTabLines'),
                  itemCount: tab.lines.length,
                  itemBuilder: (context, index) =>
                      _line(tab.lines[index], index, currencyId),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.total,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    tab.grandTotal.currency(currencyId: currencyId),
                    key: const Key('posTabTotal'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('posSend'),
                  onPressed: hasNew && ready
                      ? () => bloc.add(const PosTabSend())
                      : null,
                  child: Text(localizations.sendToKitchen),
                ),
              ),
              const SizedBox(height: 8),
              if (total == Decimal.zero)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('posCancelTab'),
                    onPressed: ready && !hasNew
                        ? () => bloc.add(const PosTabCancel())
                        : null,
                    child: Text(localizations.freeTable),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('posSplit'),
                        onPressed: ready ? _split : null,
                        child: Text(localizations.splitBill),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('posPay'),
                        onPressed: ready ? () => _pay(tab) : null,
                        child: Text(localizations.pay),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(PosTabLine line, int index, String currencyId) {
    final localizations = PosLocalizations.of(context)!;
    final bloc = context.read<PosTabBloc>();
    final isNew = line.kitchenStatus == 'New';
    final voided = line.kitchenStatus == 'Voided';
    final status = switch (line.kitchenStatus) {
      'Sent' => localizations.statusSent,
      'Ready' => localizations.statusReady,
      'Served' => localizations.statusServed,
      'Voided' => localizations.statusVoided,
      _ => localizations.statusNew,
    };
    final quantity = line.quantity ?? Decimal.one;
    return ListTile(
      key: Key('posTabLine$index'),
      dense: true,
      title: Text(
        '${voided ? '' : '$quantity x '}${line.description ?? ''}',
        style: voided
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          status,
          line.price.currency(currencyId: currencyId),
          if (line.note?.isNotEmpty ?? false) line.note!,
        ].join(' · '),
        key: Key('posTabLineStatus$index'),
      ),
      trailing: voided
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew)
                  IconButton(
                    key: Key('posTabPlus$index'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => bloc.add(
                      PosTabChangeLine(
                        line.orderItemSeqId!,
                        quantity + Decimal.one,
                      ),
                    ),
                  ),
                IconButton(
                  key: Key('posTabVoid$index'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _void(line),
                ),
              ],
            ),
    );
  }
}
