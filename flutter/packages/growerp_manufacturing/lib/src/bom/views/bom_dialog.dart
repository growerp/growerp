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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bom.dart';

class BomDialog extends StatefulWidget {
  /// Existing BOM assembly product. Null means creating a new BOM.
  final Bom? bom;
  const BomDialog({this.bom, super.key});
  @override
  BomDialogState createState() => BomDialogState();
}

class BomDialogState extends State<BomDialog> {
  late BomBloc _bomBloc;
  late RestClient _restClient;
  late String _classificationId;

  // New BOM creation fields (used when widget.bom == null)
  final _pseudoIdController = TextEditingController();
  final _productNameController = TextEditingController();

  /// Set after the product is created; switches dialog to "existing BOM" mode.
  Bom? _createdBom;
  bool _isCreating = false;

  // Add-component form state
  int _addFormKey = 0; // incremented to force-reset AutocompleteLabel
  Product? _selectedComponent;
  final _quantityController = TextEditingController();
  final _scrapFactorController = TextEditingController();
  final _seqNumController = TextEditingController();

  /// True when we dispatched BomUpdate/BomDelete (vs initial BomFetch).
  bool _formAction = false;

  Bom? get _effectiveBom => widget.bom ?? _createdBom;

  String _productDisplay(Product p) =>
      '${p.pseudoId}${p.productName != null ? "  ${p.productName}" : ""}';

  bool _canSubmit() {
    if (_selectedComponent == null) return false;
    if (_effectiveBom == null) {
      return _productNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _bomBloc = context.read<BomBloc>();
    _restClient = _bomBloc.restClient;
    _classificationId = context.read<String>();
    if (widget.bom != null) {
      _bomBloc.add(BomFetch(productId: widget.bom!.productId, refresh: true));
    }
    _quantityController.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBom = _effectiveBom;
    final isNew = effectiveBom == null;
    final title = isNew ? 'New BOM' : 'BOM: ${effectiveBom.productPseudoId}';

    return Dialog(
      key: const Key('BomDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocConsumer<BomBloc, BomState>(
        listener: (context, state) {
          if (state.status == BomStatus.success && _formAction) {
            _formAction = false;
            setState(() {
              _addFormKey++;
              _selectedComponent = null;
              _quantityController.text = '1';
              _scrapFactorController.clear();
              _seqNumController.clear();
            });
            HelperFunctions.showMessage(context, 'Done', Colors.green);
            // Reload component list to get fresh availability data
            if (_effectiveBom != null) {
              _bomBloc.add(
                BomFetch(productId: _effectiveBom!.productId, refresh: true),
              );
            }
          } else if (state.status == BomStatus.failure) {
            HelperFunctions.showMessage(
              context,
              'Error: ${state.message ?? ""}',
              Colors.red,
            );
          }
        },
        builder: (context, state) {
          final bomItems = state.bomItems;

          return popUp(
            context: context,
            title: title,
            height: 620,
            width: 500,
            child: ListView(
              key: const Key('listView'),
              children: [
                // ── Assembly header ──────────────────────────────────────
                if (isNew) ...[
                  TextFormField(
                    key: const Key('pseudoId'),
                    controller: _pseudoIdController,
                    decoration: const InputDecoration(
                      labelText: 'Product ID (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('productName'),
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ] else ...[
                  Text(
                    '${effectiveBom.productPseudoId}'
                    '${effectiveBom.productName != null ? "  ${effectiveBom.productName}" : ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Component list ───────────────────────────────────────
                if (state.status == BomStatus.loading && bomItems.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (bomItems.isNotEmpty)
                  ...bomItems.asMap().entries.map(
                    (e) => _buildComponentTile(context, e.value, e.key),
                  ),

                const Divider(height: 28),

                // ── Add-component form ───────────────────────────────────
                Text(
                  isNew ? 'First Component *' : 'Add Component',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                AutocompleteLabel<Product>(
                  key: Key('componentId$_addFormKey'),
                  label: 'Component Product',
                  optionsBuilder: (TextEditingValue v) async {
                    final r = await _restClient.getProduct(
                      searchString: v.text,
                      limit: 5,
                      isForDropDown: true,
                    );
                    return r.products;
                  },
                  displayStringForOption: _productDisplay,
                  onSelected: (Product? p) =>
                      setState(() => _selectedComponent = p),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('quantity'),
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const Key('scrapFactor'),
                        controller: _scrapFactorController,
                        decoration:
                            const InputDecoration(labelText: 'Scrap (0–1)'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const Key('sequenceNum'),
                        controller: _seqNumController,
                        decoration: const InputDecoration(labelText: 'Seq #'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isCreating)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    key: const Key('addComponent'),
                    onPressed: _canSubmit()
                        ? (isNew ? _createBom : _addComponent)
                        : null,
                    child: Text(isNew ? 'Create BOM' : 'Add Component'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComponentTile(BuildContext context, BomItem item, int index) {
    final Decimal qty = item.quantity ?? Decimal.one;
    final Decimal avail = item.availableQuantity ?? Decimal.zero;
    final bool sufficient = avail >= qty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.componentPseudoId,
                  key: Key('componentPseudoId$index'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if ((item.componentName ?? '').isNotEmpty)
                  Text(
                    item.componentName!,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          Text('${item.quantity ?? 1}', key: Key('quantity$index')),
          const SizedBox(width: 6),
          Icon(
            sufficient ? Icons.check_circle : Icons.warning_amber,
            color: sufficient ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 2),
          Text(
            avail.toString(),
            key: Key('availability$index'),
            style: TextStyle(
              fontSize: 11,
              color: sufficient ? Colors.green : Colors.orange,
            ),
          ),
          IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete_outline, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                'Delete ${item.componentPseudoId}?',
                'Cannot be undone',
              );
              if (ok == true) {
                _formAction = true;
                _bomBloc.add(BomDelete(item));
              }
            },
          ),
        ],
      ),
    );
  }

  /// Creates the assembly product via the standard create#Product service,
  /// then adds the first BOM component.
  Future<void> _createBom() async {
    setState(() => _isCreating = true);
    try {
      final product = await _restClient.createProduct(
        product: Product(
          pseudoId: _pseudoIdController.text.trim(),
          productName: _productNameController.text.trim(),
          productTypeId: 'Physical Good',
          useWarehouse: true,
          assetClassId: 'AsClsInventoryFin',
        ),
        classificationId: _classificationId,
      );
      if (!mounted) return;
      setState(() {
        _createdBom = Bom(
          productId: product.productId,
          productPseudoId: product.pseudoId,
          productName: product.productName,
        );
        _isCreating = false;
      });
      // Add the first component via BLoC
      _formAction = true;
      _bomBloc.add(
        BomUpdate(
          BomItem(
            productId: product.productId,
            productPseudoId: product.pseudoId,
            toProductId: _selectedComponent!.pseudoId,
            componentPseudoId: _selectedComponent!.pseudoId,
            quantity:
                Decimal.tryParse(_quantityController.text) ?? Decimal.one,
            scrapFactor: _scrapFactorController.text.isNotEmpty
                ? Decimal.tryParse(_scrapFactorController.text)
                : null,
            sequenceNum: int.tryParse(_seqNumController.text),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      HelperFunctions.showMessage(context, 'Error: $e', Colors.red);
    }
  }

  void _addComponent() {
    _formAction = true;
    _bomBloc.add(
      BomUpdate(
        BomItem(
          productId: _effectiveBom!.productId,
          productPseudoId: _effectiveBom!.productPseudoId,
          toProductId: _selectedComponent!.pseudoId,
          componentPseudoId: _selectedComponent!.pseudoId,
          quantity: Decimal.tryParse(_quantityController.text) ?? Decimal.one,
          scrapFactor: _scrapFactorController.text.isNotEmpty
              ? Decimal.tryParse(_scrapFactorController.text)
              : null,
          sequenceNum: int.tryParse(_seqNumController.text),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _scrapFactorController.dispose();
    _seqNumController.dispose();
    super.dispose();
  }
}
