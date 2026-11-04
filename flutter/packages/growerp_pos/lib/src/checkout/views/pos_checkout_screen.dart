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
import '../blocs/pos_cart_bloc.dart';
import '../blocs/pos_catalog_bloc.dart';
import '../blocs/pos_sale_bloc.dart';
import '../../refund/blocs/pos_refund_bloc.dart';
import '../../refund/views/pos_refund_dialog.dart';
import 'pos_receipt_dialog.dart';
import 'pos_tender_dialog.dart';

/// Width from which the cart stands next to the products.
const double _sideBySideWidth = 700;

/// The till: products to tap or scan on one side, the sale on the other. On a
/// narrow screen the sale sits under the products.
class PosCheckoutScreen extends StatefulWidget {
  const PosCheckoutScreen({super.key});

  @override
  PosCheckoutScreenState createState() => PosCheckoutScreenState();
}

class PosCheckoutScreenState extends State<PosCheckoutScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _search = '';
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    context.read<PosCatalogBloc>().add(const PosCatalogFetch());
  }

  /// A scanner types the code and presses enter.
  void _onSubmitted(String value) {
    final code = value.trim();
    _searchController.clear();
    setState(() => _search = '');
    _searchFocus.requestFocus();
    if (code.isNotEmpty) {
      context.read<PosCatalogBloc>().add(PosBarcodeScan(code));
    }
  }

  List<PosCatalogItem> _visible(PosCatalogState state) {
    final search = _search.toLowerCase();
    return state.items
        .where(
          (item) =>
              (_categoryId == null ||
                  item.categories.any((c) => c.categoryId == _categoryId)) &&
              (search.isEmpty ||
                  (item.productName ?? '').toLowerCase().contains(search) ||
                  (item.pseudoId ?? '').toLowerCase().contains(search)),
        )
        .toList();
  }

  Future<void> _pay(PosCartState cart, String currencyId) async {
    final saleBloc = context.read<PosSaleBloc>();
    final cartBloc = context.read<PosCartBloc>();
    final sale = await showDialog<PosSale>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: saleBloc,
        child: PosTenderDialog(
          lines: cart.lines
              .map(
                (line) => PosLine(
                  productId: line.item.productId,
                  quantity: line.quantity,
                ),
              )
              .toList(),
          grandTotal: cart.grandTotal ?? Decimal.zero,
          currencyId: currencyId,
        ),
      ),
    );
    if (sale == null || !mounted) return;
    cartBloc.add(const PosCartClear());
    saleBloc.add(const PosSaleReset());
    await showDialog(context: context, builder: (_) => PosReceiptDialog(sale));
    _searchFocus.requestFocus();
  }

  Future<void> _refund() async {
    final bloc = context.read<PosRefundBloc>()..add(const PosRefundReset());
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const PosRefundDialog()),
    );
    if (mounted) _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PosCatalogBloc, PosCatalogState>(
          listener: (context, state) {
            if (state.status == PosCatalogStatus.failure) {
              HelperFunctions.showMessage(context, state.message, Colors.red);
            }
            if (state.status == PosCatalogStatus.scanned) {
              context.read<PosCartBloc>().add(PosCartAdd(state.scanned!));
            }
          },
        ),
        BlocListener<PosCartBloc, PosCartState>(
          listener: (context, state) {
            if (state.status == PosCartStatus.failure) {
              HelperFunctions.showMessage(context, state.message, Colors.red);
            }
          },
        ),
      ],
      child: LayoutBuilder(
        key: const Key('PosCheckoutScreen'),
        builder: (context, constraints) {
          if (constraints.maxWidth >= _sideBySideWidth) {
            return Row(
              children: [
                Expanded(child: _catalog()),
                const VerticalDivider(width: 1),
                SizedBox(width: 340, child: _cart()),
              ],
            );
          }
          return Column(
            children: [
              Expanded(flex: 3, child: _catalog()),
              const Divider(height: 1),
              Expanded(flex: 2, child: _cart()),
            ],
          );
        },
      ),
    );
  }

  Widget _catalog() {
    final localizations = PosLocalizations.of(context)!;
    return BlocBuilder<PosCatalogBloc, PosCatalogState>(
      builder: (context, state) {
        if (state.status == PosCatalogStatus.initial ||
            (state.status == PosCatalogStatus.loading && state.items.isEmpty)) {
          return const Center(child: LoadingIndicator());
        }
        final items = _visible(state);
        final categories = <String, String>{
          for (final item in state.items)
            for (final category in item.categories)
              category.categoryId: category.categoryName,
        };
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                key: const Key('posSearch'),
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  hintText: localizations.searchOrScan,
                  suffixIcon: IconButton(
                    key: const Key('posRefresh'),
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<PosCatalogBloc>().add(
                      const PosCatalogFetch(refresh: true),
                    ),
                  ),
                ),
                onChanged: (value) => setState(() => _search = value),
                onSubmitted: _onSubmitted,
              ),
            ),
            if (categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  key: const Key('posCategories'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: const Key('posCategoryAll'),
                        label: Text(localizations.allProducts),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                    ),
                    for (final category in categories.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: Key('posCategory${category.key}'),
                          label: Text(category.value),
                          selected: _categoryId == category.key,
                          onSelected: (_) =>
                              setState(() => _categoryId = category.key),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      key: const Key('posNoProducts'),
                      child: Text(localizations.noProducts),
                    )
                  : GridView.builder(
                      key: const Key('posGrid'),
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _tile(items[index], index, state.currencyId ?? 'USD'),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(PosCatalogItem item, int index, String currencyId) {
    return Card(
      key: Key('posItem$index'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.read<PosCartBloc>().add(PosCartAdd(item)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: item.image != null
                  ? Image.memory(item.image!, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2_outlined, size: 36),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.price.currency(currencyId: currencyId),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cart() {
    final localizations = PosLocalizations.of(context)!;
    return BlocBuilder<PosCatalogBloc, PosCatalogState>(
      buildWhen: (old, state) => old.currencyId != state.currencyId,
      builder: (context, catalog) {
        final currencyId = catalog.currencyId ?? 'USD';
        return BlocBuilder<PosCartBloc, PosCartState>(
          builder: (context, cart) {
            return Column(
              children: [
                Expanded(
                  child: cart.lines.isEmpty
                      ? Center(
                          key: const Key('posCartEmpty'),
                          child: Text(localizations.cartEmpty),
                        )
                      : ListView.builder(
                          key: const Key('posCart'),
                          itemCount: cart.lines.length,
                          itemBuilder: (context, index) =>
                              _line(cart.lines[index], index, currencyId),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (cart.lines.isNotEmpty &&
                          (cart.taxTotal ?? Decimal.zero) != Decimal.zero)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              catalog.pricesIncludeTax
                                  ? localizations.includedTax
                                  : localizations.tax,
                            ),
                            Text(
                              cart.taxTotal.currency(currencyId: currencyId),
                              key: const Key('posTax'),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.total,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            cart.lines.isEmpty
                                ? Decimal.zero.currency(currencyId: currencyId)
                                : cart.grandTotal.currency(
                                    currencyId: currencyId,
                                  ),
                            key: const Key('posTotal'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isAdmin(context)) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: const Key('posRefund'),
                            onPressed: _refund,
                            child: Text(localizations.refund),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('posPay'),
                          // the total must be the one of the lines shown
                          onPressed:
                              cart.lines.isNotEmpty &&
                                  cart.status == PosCartStatus.success
                              ? () => _pay(cart, currencyId)
                              : null,
                          child: Text(localizations.pay),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// The backend decides, this only hides the button from a cashier.
  bool _isAdmin(BuildContext context) {
    final group = context.read<AuthBloc>().state.authenticate?.user?.userGroup;
    return group == UserGroup.admin;
  }

  Widget _line(PosCartLine line, int index, String currencyId) {
    final bloc = context.read<PosCartBloc>();
    final productId = line.item.productId!;
    return ListTile(
      key: Key('posLine$index'),
      dense: true,
      title: Text(line.item.productName ?? ''),
      subtitle: Text(line.total.currency(currencyId: currencyId)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('posLineMinus$index'),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => bloc.add(
              PosCartQuantity(productId, line.quantity - Decimal.one),
            ),
          ),
          Text('${line.quantity}', key: Key('posLineQuantity$index')),
          IconButton(
            key: Key('posLinePlus$index'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => bloc.add(
              PosCartQuantity(productId, line.quantity + Decimal.one),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
