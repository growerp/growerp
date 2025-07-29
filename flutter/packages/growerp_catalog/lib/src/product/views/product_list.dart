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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../product.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});
  @override
  ProductListState createState() => ProductListState();
}

class ProductListState extends State<ProductList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late ProductBloc _productBloc;
  late List<Product> products;
  late String classificationId;
  late String entityName;
  late bool started;
  late int limit;
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _productBloc = context.read<ProductBloc>()
      ..add(const ProductFetch(refresh: true));
    classificationId = context.read<String>();
    entityName = classificationId == 'AppHotel' ? 'Room Type' : 'Product';
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 100).round();
    right = right ?? (isAPhone(context) ? 20 : 50);

    Widget tableView() {
      if (products.isEmpty) {
        return Center(
            child: Text("No ${entityName}s found, add one with '+'",
                style: const TextStyle(fontSize: 20.0)));
      }
      // get table data formatted for tableView
      var (
        List<List<TableViewCell>> tableViewCells,
        List<double> fieldWidths,
        double? rowHeight
      ) = get2dTableData<Product>(getTableData,
          bloc: _productBloc,
          classificationId: classificationId,
          context: context,
          items: products);
      return TableView.builder(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        verticalDetails:
            ScrollableDetails.vertical(controller: _scrollController),
        horizontalDetails:
            ScrollableDetails.horizontal(controller: _horizontalController),
        cellBuilder: (context, vicinity) =>
            tableViewCells[vicinity.row][vicinity.column],
        columnBuilder: (index) => index >= tableViewCells[0].length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(fieldWidths[index]),
              ),
        pinnedColumnCount: 1,
        rowBuilder: (index) => index >= tableViewCells.length
            ? null
            : TableSpan(
                padding: padding,
                backgroundDecoration: getBackGround(context, index),
                extent: FixedTableSpanExtent(rowHeight!),
                recognizerFactories: <Type, GestureRecognizerFactory>{
                    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                            TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return index > products.length
                                  ? const BottomLoader()
                                  : Dismissible(
                                      key: const Key('productItem'),
                                      direction: DismissDirection.startToEnd,
                                      child: BlocProvider.value(
                                          value: _productBloc,
                                          child: ProductDialog(
                                              products[index - 1])));
                            }))
                  }),
        pinnedRowCount: 1,
      );
    }

    return BlocConsumer<ProductBloc, ProductState>(
        listenWhen: (previous, current) =>
            previous.status == ProductStatus.loading,
        listener: (context, state) {
          if (state.status == ProductStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == ProductStatus.success) {
            started = true;
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case ProductStatus.failure:
              return Center(
                  child: Text('failed to fetch product: ${state.message}'));
            case ProductStatus.success:
              products = state.products;
              return Stack(
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
                                key: const Key("search"),
                                heroTag: "btn1",
                                onPressed: () async {
                                  // find findoc id to show
                                  await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        // search separate from finDocBloc
                                        return BlocProvider.value(
                                            value: context.read<
                                                DataFetchBloc<Locations>>(),
                                            child: const SearchProductList());
                                      }).then((value) async => value != null &&
                                          context.mounted
                                      ?
                                      // show detail page
                                      await showDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return BlocProvider.value(
                                                value: _productBloc,
                                                child: ProductDialog(value));
                                          })
                                      : const SizedBox.shrink());
                                },
                                child: const Icon(Icons.search)),
                            const SizedBox(height: 10),
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
                                            child: const ProductFilesDialog());
                                      });
                                },
                                tooltip: 'products up/download',
                                child: const Icon(Icons.file_copy)),
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
                                            child:
                                                const ProductDialog(Product()));
                                      });
                                },
                                tooltip: CoreLocalizations.of(context)!.addNew,
                                child: const Icon(Icons.add))
                          ]),
                    ),
                  ),
                ],
              );
            default:
              return const Center(child: LoadingIndicator());
          }
        });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _productBloc.add(ProductFetch(limit: limit));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
