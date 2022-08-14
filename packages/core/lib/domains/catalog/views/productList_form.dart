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
import 'package:global_configuration/global_configuration.dart';
import '../../domains.dart';
import '../../../api_repository.dart';
import '../../common/functions/helper_functions.dart';

class ProductListForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          ProductBloc(context.read<APIRepository>())..add(ProductFetch()),
      child: ProductList(),
    );
  }
}

class ProductList extends StatefulWidget {
  const ProductList();
  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<ProductList> {
  final _scrollController = ScrollController();
  late Authenticate authenticate;
  late ProductBloc _productBloc;
  late int limit;
  late bool search;
  String? searchString;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  late bool started;

  @override
  void initState() {
    super.initState();
    started = false;
    entityName = classificationId == 'AppHotel' ? 'Room Type' : 'Product';
    _scrollController.addListener(_onScroll);
    _productBloc = context.read<ProductBloc>();
    search = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
        listenWhen: (previous, current) =>
            previous.status == ProductStatus.loading,
        listener: (context, state) {
          if (state.status == ProductStatus.failure)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('productList form'),
              duration: const Duration(seconds: 1),
            ));
          if (state.status == ProductStatus.success) {
            started = true;
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          return Stack(children: [
            Scaffold(
                floatingActionButton:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  FloatingActionButton(
                      heroTag: 'files',
                      key: Key("upDownload"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _productBloc,
                                  child: ProductFilesDialog());
                            });
                      },
                      tooltip: 'products up/download',
                      child: Icon(Icons.file_copy)),
                  SizedBox(height: 10),
                  FloatingActionButton(
                      heroTag: 'new',
                      key: Key("addNew"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _productBloc,
                                  child: ProductDialog(Product()));
                            });
                      },
                      tooltip: 'Add New',
                      child: Icon(Icons.add))
                ]),
                body: RefreshIndicator(
                    onRefresh: () async => context
                        .read<ProductBloc>()
                        .add(const ProductFetch(refresh: true)),
                    child: ListView.builder(
                        key: Key('listView'),
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: state.hasReachedMax
                            ? state.products.length + 1
                            : state.products.length + 2,
                        controller: _scrollController,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0)
                            return Column(children: [
                              ProductListHeader(),
                              Visibility(
                                  visible: state.products.isEmpty,
                                  child: Center(
                                      heightFactor: 20,
                                      child: Text(
                                          started ? 'No products found' : '',
                                          key: Key('empty'),
                                          textAlign: TextAlign.center)))
                            ]);
                          index--;
                          return index >= state.products.length
                              ? BottomLoader()
                              : Dismissible(
                                  key: Key('productItem'),
                                  direction: DismissDirection.startToEnd,
                                  child: ProductListItem(
                                      product: state.products[index],
                                      index: index));
                        }))),
            if (state.status == ProductStatus.loading) LoadingIndicator()
          ]);
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
    if (_isBottom) context.read<ProductBloc>().add(ProductFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
