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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../product.dart';

class ProductListForm extends StatelessWidget {
  const ProductListForm({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ProductBloc>(
      create: (BuildContext context) => ProductBloc(CatalogAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!)),
      child: const ProductList());
}

class ProductList extends StatefulWidget {
  const ProductList({super.key});
  @override
  ProductListState createState() => ProductListState();
}

class ProductListState extends State<ProductList> {
  final _scrollController = ScrollController();
  late ProductBloc _productBloc;
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
    _productBloc.add(const ProductFetch());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProductBloc, ProductState>(
      listenWhen: (previous, current) =>
          previous.status == ProductStatus.loading,
      listener: (context, state) {
        if (state.status == ProductStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
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
            return Scaffold(
                floatingActionButton:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                                  child: ProductDialog(Product()));
                            });
                      },
                      tooltip: CoreLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add))
                ]),
                body: Column(children: [
                  const ProductListHeader(),
                  Expanded(
                      child: RefreshIndicator(
                          onRefresh: () async => _productBloc
                              .add(const ProductFetch(refresh: true)),
                          child: ListView.builder(
                              key: const Key('listView'),
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: state.hasReachedMax
                                  ? state.products.length + 1
                                  : state.products.length + 2,
                              controller: _scrollController,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == 0) {
                                  return Visibility(
                                      visible: state.products.isEmpty,
                                      child: Center(
                                          heightFactor: 20,
                                          child: Text(
                                              started
                                                  ? classificationId ==
                                                          'AppHotel'
                                                      ? 'No Room Types found'
                                                      : 'No Products found'
                                                  : '',
                                              key: const Key('empty'),
                                              textAlign: TextAlign.center)));
                                }
                                index--;
                                return index >= state.products.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key('productItem'),
                                        direction: DismissDirection.startToEnd,
                                        child: ProductListItem(
                                            product: state.products[index],
                                            index: index));
                              })))
                ]));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      });

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<ProductBloc>().add(const ProductFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
