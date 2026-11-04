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
import '../blocs/pos_sale_bloc.dart';

/// Take the payment: one or more tenders until the total is covered. Pops with
/// the finished sale.
class PosTenderDialog extends StatefulWidget {
  const PosTenderDialog({
    super.key,
    required this.lines,
    required this.grandTotal,
    required this.currencyId,
    required this.terminalName,
  });
  final String terminalName;
  final List<PosLine> lines;
  final Decimal grandTotal;
  final String currencyId;

  @override
  PosTenderDialogState createState() => PosTenderDialogState();
}

class PosTenderDialogState extends State<PosTenderDialog> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final List<PosTender> _tenders = [];

  Decimal get _paid =>
      _tenders.fold(Decimal.zero, (sum, t) => sum + (t.amount ?? Decimal.zero));
  Decimal get _remaining => widget.grandTotal - _paid;
  bool get _covered => _remaining <= Decimal.zero;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.grandTotal.toString();
  }

  void _add(String method) {
    final amount = Decimal.tryParse(_amountController.text);
    if (amount == null || amount <= Decimal.zero) return;
    setState(() {
      _tenders.add(
        PosTender(
          method: method,
          amount: amount,
          reference: _referenceController.text.isEmpty
              ? null
              : _referenceController.text,
        ),
      );
      _referenceController.clear();
      _amountController.text = _covered ? '' : _remaining.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    String money(Decimal? amount) =>
        amount.currency(currencyId: widget.currencyId);
    return Dialog(
      key: const Key('PosTenderDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocConsumer<PosSaleBloc, PosSaleState>(
        listener: (context, state) {
          if (state.status == PosSaleStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosSaleStatus.success) {
            Navigator.of(context).pop(state.sale);
          }
        },
        builder: (context, state) {
          final busy = state.status == PosSaleStatus.loading;
          return popUp(
            context: context,
            title: localizations.payment,
            height: 520,
            width: 400,
            child: ListView(
              key: const Key('listView'),
              children: [
                Text(
                  money(widget.grandTotal),
                  key: const Key('posTenderTotal'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('posAmount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: localizations.amount),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('posReference'),
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: localizations.cardReference,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('posCash'),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(localizations.cash),
                        onPressed: _covered || busy
                            ? null
                            : () => _add('PiCash'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('posCard'),
                        icon: const Icon(Icons.credit_card),
                        label: Text(localizations.card),
                        onPressed: _covered || busy
                            ? null
                            : () => _add('PiCreditCard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final (index, tender) in _tenders.indexed)
                  ListTile(
                    key: Key('posTender$index'),
                    dense: true,
                    title: Text(
                      tender.method == 'PiCash'
                          ? localizations.cash
                          : localizations.card,
                    ),
                    trailing: Text(money(tender.amount)),
                  ),
                ListTile(
                  dense: true,
                  title: Text(
                    _covered ? localizations.change : localizations.remaining,
                  ),
                  trailing: Text(
                    money(_covered ? _paid - widget.grandTotal : _remaining),
                    key: const Key('posRemaining'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('posCancel'),
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(localizations.cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('posComplete'),
                        onPressed: _covered && !busy
                            ? () => context.read<PosSaleBloc>().add(
                                PosSaleSubmit(
                                  lines: widget.lines,
                                  tenders: _tenders,
                                  terminalName: widget.terminalName,
                                ),
                              )
                            : null,
                        child: Text(localizations.completeSale),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
