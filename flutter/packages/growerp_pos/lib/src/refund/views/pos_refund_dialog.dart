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
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../../checkout/views/pos_receipt.dart';
import '../blocs/pos_refund_bloc.dart';

/// Find a sale by the invoice number on its receipt, pick what comes back and
/// give the money back.
class PosRefundDialog extends StatefulWidget {
  const PosRefundDialog({super.key});

  @override
  PosRefundDialogState createState() => PosRefundDialogState();
}

class PosRefundDialogState extends State<PosRefundDialog> {
  final _searchController = TextEditingController();
  final Map<String, Decimal> _quantities = {};
  bool _restock = true;

  List<PosRefundLine> get _lines => _quantities.entries
      .where((entry) => entry.value > Decimal.zero)
      .map(
        (entry) =>
            PosRefundLine(orderItemSeqId: entry.key, quantity: entry.value),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Dialog(
      key: const Key('PosRefundDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocConsumer<PosRefundBloc, PosRefundState>(
        listener: (context, state) {
          if (state.status == PosRefundStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
        },
        builder: (context, state) => popUp(
          context: context,
          title: localizations.refund,
          height: 540,
          width: 420,
          child: state.refund != null
              ? _done(context, state.refund!, localizations)
              : _form(context, state, localizations),
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    PosRefundState state,
    PosLocalizations localizations,
  ) {
    final sale = state.sale;
    final busy = state.status == PosRefundStatus.loading;
    final bloc = context.read<PosRefundBloc>();
    return ListView(
      key: const Key('listView'),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('posRefundSearch'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: localizations.receiptNumber,
                ),
                onSubmitted: (value) => bloc.add(PosRefundLookup(value.trim())),
              ),
            ),
            IconButton(
              key: const Key('posRefundFind'),
              icon: const Icon(Icons.search),
              onPressed: busy
                  ? null
                  : () => bloc.add(
                      PosRefundLookup(_searchController.text.trim()),
                    ),
            ),
          ],
        ),
        if (sale != null) ...[
          const SizedBox(height: 8),
          for (final (index, line) in sale.lines.indexed)
            _line(line, index, sale.currencyId ?? 'USD'),
          SwitchListTile(
            key: const Key('posRestock'),
            title: Text(localizations.backInStock),
            value: _restock,
            onChanged: (value) => setState(() => _restock = value),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('posRefundConfirm'),
            onPressed: _lines.isEmpty || busy
                ? null
                : () => bloc.add(
                    PosRefundSubmit(lines: _lines, restock: _restock),
                  ),
            child: Text(localizations.refund),
          ),
        ],
      ],
    );
  }

  Widget _line(PosSaleLine line, int index, String currencyId) {
    final seqId = line.orderItemSeqId!;
    final quantity = _quantities[seqId] ?? Decimal.zero;
    final max = line.returnableQuantity ?? Decimal.zero;
    return ListTile(
      key: Key('posRefundLine$index'),
      dense: true,
      title: Text(line.description ?? ''),
      subtitle: Text(line.price.currency(currencyId: currencyId)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('posRefundMinus$index'),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity > Decimal.zero
                ? () => setState(
                    () => _quantities[seqId] = quantity - Decimal.one,
                  )
                : null,
          ),
          Text('$quantity / $max', key: Key('posRefundQuantity$index')),
          IconButton(
            key: Key('posRefundPlus$index'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: quantity < max
                ? () => setState(
                    () => _quantities[seqId] = quantity + Decimal.one,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _done(
    BuildContext context,
    PosRefund refund,
    PosLocalizations localizations,
  ) {
    final currencyId = refund.currencyId ?? 'USD';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          refund.method == 'PiCash' ? localizations.cash : localizations.card,
        ),
        Text(
          refund.amount.currency(currencyId: currencyId),
          key: const Key('posRefundAmount'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('posRefundPrint'),
                icon: const Icon(Icons.print),
                label: Text(localizations.print),
                onPressed: () {
                  final authenticate = context
                      .read<AuthBloc>()
                      .state
                      .authenticate;
                  Printing.layoutPdf(
                    format: PdfPageFormat.roll80,
                    onLayout: (_) => buildPosRefundReceipt(
                      refund,
                      companyName: authenticate?.company?.name ?? '',
                      title: localizations.refund,
                      labels: PosReceiptLabels.of(localizations),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                key: const Key('posRefundDone'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.close),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
