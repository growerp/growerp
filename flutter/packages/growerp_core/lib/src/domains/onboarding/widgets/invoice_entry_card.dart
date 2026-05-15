/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class InvoiceEntryCard extends StatefulWidget {
  const InvoiceEntryCard({
    super.key,
    this.headline,
    this.pseudoId,
    this.customerName,
    this.status,
    this.description,
    required this.items,
    required this.onSubmit,
  });

  final String? headline;
  final String? pseudoId;
  final String? customerName;
  final String? status;
  final String? description;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(String text) onSubmit;

  @override
  State<InvoiceEntryCard> createState() => _InvoiceEntryCardState();

  static CatalogItem catalogItem({
    required Future<void> Function(String) onSubmit,
  }) =>
      CatalogItem(
        name: 'InvoiceEntryCard',
        dataSchema: Schema.object(
          description:
              'Invoice entry form with header fields (id, customer, status, description) and editable line items.',
          properties: {
            'headline': Schema.string(),
            'pseudoId': Schema.string(),
            'customerName': Schema.string(),
            'status': Schema.string(),
            'description': Schema.string(),
            'items': Schema.list(
              items: Schema.object(
                properties: {
                  'description': Schema.string(),
                  'quantity': Schema.number(),
                  'price': Schema.number(),
                },
                required: ['description', 'quantity', 'price'],
              ),
            ),
          },
          required: ['headline', 'items'],
        ),
        widgetBuilder: (ctx) {
          final data = ctx.data as Map<String, dynamic>;
          final rawItems = (data['items'] as List?)
                  ?.whereType<Map<String, dynamic>>()
                  .toList() ??
              [];
          return InvoiceEntryCard(
            headline: data['headline'] as String?,
            pseudoId: data['pseudoId'] as String?,
            customerName: data['customerName'] as String?,
            status: data['status'] as String?,
            description: data['description'] as String?,
            items: rawItems,
            onSubmit: onSubmit,
          );
        },
      );
}

class _ItemEntry {
  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController price;

  _ItemEntry({String desc = '', String qty = '1', String price = ''})
      : desc = TextEditingController(text: desc),
        qty = TextEditingController(text: qty),
        price = TextEditingController(text: price);

  double get total {
    final q = double.tryParse(qty.text) ?? 0;
    final p = double.tryParse(price.text) ?? 0;
    return q * p;
  }

  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
  }
}

class _InvoiceEntryCardState extends State<InvoiceEntryCard> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pseudoIdController;
  late TextEditingController _customerController;
  late TextEditingController _descriptionController;
  late String _status;
  late List<_ItemEntry> _items;
  bool _submitting = false;

  static const _statusOptions = [
    'In Preparation',
    'Created',
    'Approved',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _pseudoIdController = TextEditingController(text: widget.pseudoId ?? '');
    _customerController =
        TextEditingController(text: widget.customerName ?? '');
    _descriptionController =
        TextEditingController(text: widget.description ?? '');
    _status = (_statusOptions.contains(widget.status) ? widget.status : null) ??
        _statusOptions.first;
    _items = widget.items
        .map((item) => _ItemEntry(
              desc: item['description'] as String? ?? '',
              qty: (item['quantity'] ?? 1).toString(),
              price: (item['price'] ?? 0).toString(),
            ))
        .toList();
    if (_items.isEmpty) _items.add(_ItemEntry());
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _customerController.dispose();
    _descriptionController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _grandTotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await widget.onSubmit(jsonEncode({
      'pseudoId': _pseudoIdController.text,
      'customerName': _customerController.text,
      'status': _status,
      'description': _descriptionController.text,
      'items': _items
          .map((item) => {
                'description': item.desc.text,
                'quantity': double.tryParse(item.qty.text) ?? 1,
                'price': double.tryParse(item.price.text) ?? 0,
              })
          .toList(),
      'grandTotal': _grandTotal,
    }));
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Text(widget.headline!, style: theme.textTheme.titleMedium),
            ),
          _buildHeader(),
          const SizedBox(height: 12),
          _buildItemsHeader(theme),
          const Divider(height: 8),
          ..._buildItemRows(theme),
          TextButton.icon(
            key: const Key('addItem'),
            onPressed: () => setState(() => _items.add(_ItemEntry())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Grand Total', style: theme.textTheme.titleSmall),
              const SizedBox(width: 16),
              Text(
                '\$${_grandTotal.toStringAsFixed(2)}',
                key: const Key('grandTotal'),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _submitting ? null : _handleSubmit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final leftCol = Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                key: const Key('pseudoId'),
                controller: _pseudoIdController,
                decoration: const InputDecoration(labelText: 'Invoice #'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const Key('customer'),
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a customer!' : null,
              ),
            ),
          ],
        ),
      ],
    );

    final rightCol = Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 145,
            child: DropdownButtonFormField<String>(
              key: const Key('statusDropDown'),
              decoration: const InputDecoration(labelText: 'Status'),
              initialValue: _status,
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
              isExpanded: true,
              validator: (v) => v == null ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: const Key('description'),
              controller: _descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Invoice description'),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(children: [leftCol, rightCol]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: leftCol),
            Expanded(child: rightCol),
          ],
        );
      },
    );
  }

  Widget _buildItemsHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
            flex: 4,
            child:
                Text('Description', style: theme.textTheme.labelSmall)),
        Expanded(
            flex: 2,
            child: Text('Qty',
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.right)),
        Expanded(
            flex: 2,
            child: Text('Price',
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.right)),
        Expanded(
            flex: 2,
            child: Text('SubTotal',
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.right)),
        const SizedBox(width: 32),
      ],
    );
  }

  List<Widget> _buildItemRows(ThemeData theme) {
    return List.generate(_items.length, (i) {
      final item = _items[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: item.desc,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: item.qty,
                decoration: const InputDecoration(isDense: true),
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: item.price,
                decoration: const InputDecoration(
                    isDense: true, prefixText: '\$'),
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: _items.length > 1
                  ? () => setState(() {
                        _items[i].dispose();
                        _items.removeAt(i);
                      })
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    });
  }
}
