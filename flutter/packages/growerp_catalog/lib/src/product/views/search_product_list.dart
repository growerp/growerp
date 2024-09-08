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

class SearchProductList extends StatefulWidget {
  const SearchProductList({super.key});

  @override
  SearchProductState createState() => SearchProductState();
}

class SearchProductState extends State<SearchProductList> {
  late DataFetchBloc _productBloc;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
          GetDataEvent(() => context.read<RestClient>().getProduct(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<Products>, DataFetchState>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        return Center(
            child: Text('failed to fetch search items: ${state.message}'));
      }
      if (state.status == DataFetchStatus.success) {
        products = (state.data as Products).products;
      }
      return Stack(
        children: [
          ProductScaffold(
              finDocBloc: _productBloc, widget: widget, products: products),
          if (state.status == DataFetchStatus.loading) const LoadingIndicator(),
        ],
      );
    });
  }
}

class ProductScaffold extends StatelessWidget {
  const ProductScaffold({
    super.key,
    required DataFetchBloc finDocBloc,
    required this.widget,
    required this.products,
  }) : _productBloc = finDocBloc;

  final DataFetchBloc _productBloc;
  final SearchProductList widget;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: const Key('SearchDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
                context: context,
                title: 'Product Search ',
                height: 500,
                width: 350,
                child: Column(children: [
                  TextFormField(
                      key: const Key('searchField'),
                      textInputAction: TextInputAction.search,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: "Search input"),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a search value?';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) => _productBloc.add(
                          GetDataEvent(() => context
                              .read<RestClient>()
                              .getProduct(limit: 5, searchString: value)))),
                  const SizedBox(height: 20),
                  const Text('Search results'),
                  Expanded(
                      child: ListView.builder(
                          key: const Key('listView'),
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: products.length + 2,
                          controller: scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Visibility(
                                  visible: products.isEmpty,
                                  child: const Center(
                                      heightFactor: 20,
                                      child: Text('No search items found (yet)',
                                          key: Key('empty'),
                                          textAlign: TextAlign.center)));
                            }
                            index--;
                            return index >= products.length
                                ? const Text('')
                                : Dismissible(
                                    key: const Key('searchItem'),
                                    direction: DismissDirection.startToEnd,
                                    child: ListTile(
                                      title: Text(
                                          "ID: ${products[index].pseudoId}\n"
                                          "Name: ${products[index].productName}",
                                          key: Key("searchResult$index")),
                                      onTap: () => Navigator.of(context)
                                          .pop(products[index]),
                                    ));
                          }))
                ]))));
  }
}
