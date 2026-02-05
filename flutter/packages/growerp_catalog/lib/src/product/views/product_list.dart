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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_catalog.dart';
import 'product_list_styled_data.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});
  @override
  ProductListState createState() => ProductListState();
}

class ProductListState extends State<ProductList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late ProductBloc _productBloc;
  List<Product> products = const <Product>[];
  late String classificationId;
  late String entityName;
  late int limit;
  late double bottom;
  double? right;
  String searchString = '';
  bool _isLoading = true;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _productBloc = context.read<ProductBloc>()
      ..add(const ProductFetch(refresh: true));
    classificationId = context.read<String>();
    entityName = classificationId == 'AppHotel' ? 'Room Type' : 'Product';
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final catalogLocalizations = CatalogLocalizations.of(context)!;
    limit = (MediaQuery.of(context).size.height / 100).round();
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = products.map((product) {
        final index = products.indexOf(product);
        return getProductListRow(
          context: context,
          product: product,
          index: index,
          bloc: _productBloc,
          classificationId: classificationId,
        );
      }).toList();

      return StyledDataTable(
        columns: getProductListColumns(
          context,
          classificationId: classificationId,
        ),
        rows: rows,
        isLoading: _isLoading && products.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('productItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _productBloc,
                  child: ProductDialog(products[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state.status == ProductStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == ProductStatus.success) {
          final translatedMessage = state.message != null
              ? translateProductBlocMessage(
                  state.message!,
                  catalogLocalizations,
                )
              : '';
          if (translatedMessage.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              translatedMessage,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == ProductStatus.loading;

        if (state.status == ProductStatus.failure) {
          return FatalErrorForm(
            message: catalogLocalizations.fetchProductError(
              state.message ?? '',
            ),
          );
        }

        products = state.products;
        if (products.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search ${entityName.toLowerCase()}s...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _productBloc.add(
                  ProductFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
                children: [
                  tableView(),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            heroTag: 'productFiles',
                            key: const Key("upDownload"),
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _productBloc,
                                    child: const ProductFilesDialog(),
                                  );
                                },
                              );
                            },
                            tooltip: catalogLocalizations.productUpDown,
                            child: const Icon(Icons.file_copy),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            heroTag: 'productNew',
                            key: const Key("addNew"),
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _productBloc,
                                    child: const ProductDialog(Product()),
                                  );
                                },
                              );
                            },
                            tooltip: CoreLocalizations.of(context)!.addNew,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom) {
      _productBloc.add(ProductFetch(limit: limit, searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
