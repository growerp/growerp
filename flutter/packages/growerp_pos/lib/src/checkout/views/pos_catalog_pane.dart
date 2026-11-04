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
import '../blocs/pos_catalog_bloc.dart';

/// What can be sold: tiles with search, categories and scanning. Used by the
/// till and by a restaurant tab.
class PosCatalogPane extends StatefulWidget {
  const PosCatalogPane({super.key, required this.onItem});
  final ValueChanged<PosCatalogItem> onItem;

  @override
  PosCatalogPaneState createState() => PosCatalogPaneState();
}

class PosCatalogPaneState extends State<PosCatalogPane> {
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

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return BlocConsumer<PosCatalogBloc, PosCatalogState>(
      listener: (context, state) {
        if (state.status == PosCatalogStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (state.status == PosCatalogStatus.scanned) {
          widget.onItem(state.scanned!);
        }
      },
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
        onTap: () => widget.onItem(item),
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
