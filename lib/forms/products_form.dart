/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:responsive_framework/responsive_framework.dart';
import '../models/@models.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../routing_constants.dart';
import '../widgets/@widgets.dart';

class ProductsForm extends StatelessWidget {
  final FormArguments formArguments;
  ProductsForm(this.formArguments);
  @override
  Widget build(BuildContext context) {
    var a = (formArguments) => (ProductsFormHeader(formArguments.message));
    return ShowNavigationRail(a(formArguments), 3);
  }
}

class ProductsFormHeader extends StatefulWidget {
  final String message;
  const ProductsFormHeader(this.message);
  @override
  _ProductsFormStateHeader createState() => _ProductsFormStateHeader(message);
}

class _ProductsFormStateHeader extends State<ProductsFormHeader> {
  final String message;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Authenticate authenticate;
  Catalog catalog;
  List<Product> products;

  _ProductsFormStateHeader(this.message) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      return ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
              appBar: AppBar(
                  title: companyLogo(context, authenticate, 'Product List'),
                  automaticallyImplyLeading:
                      ResponsiveWrapper.of(context).isSmallerThan(TABLET)),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, ProductRoute,
                      arguments:
                          FormArguments('Enter the product information'));
                },
                tooltip: 'Add new product',
                child: Icon(Icons.add),
              ),
              body: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthProblem)
                      HelperFunctions.showMessage(
                          context, '${state.errorMessage}', Colors.red);
                  },
                  child: BlocConsumer<CatalogBloc, CatalogState>(
                      listener: (context, state) {
                    if (state is CatalogProblem)
                      HelperFunctions.showMessage(
                          context, '${state.errorMessage}', Colors.red);
                    if (state is CatalogLoaded)
                      HelperFunctions.showMessage(
                          context, '${state.message}', Colors.green);
                    if (state is CatalogLoading)
                      HelperFunctions.showMessage(
                          context, '${state.message}', Colors.green);
                  }, builder: (context, state) {
                    if (state is CatalogLoaded) {
                      catalog = state.catalog;
                      products = catalog.products;
                    }
                    return productList();
                  }))));
    });
  }

  Widget productList() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          // you could add any widget
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                    child: Text("Product name [Id] ",
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text("Description", textAlign: TextAlign.center)),
                Expanded(child: Text("price", textAlign: TextAlign.center)),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(
                      child:
                          Text("Category [id]", textAlign: TextAlign.center)),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return InkWell(
                onTap: () async {
                  dynamic user = await Navigator.pushNamed(
                      context, ProductRoute,
                      arguments: FormArguments(null, products[index]));
                  setState(() {
                    if (user != null)
                      products.replaceRange(index, index + 1, [user]);
                  });
                },
                onLongPress: () async {
                  bool result = await confirmDialog(context,
                      "${products[index].productName}", "Delete this product?");
                  if (result) {
                    BlocProvider.of<CatalogBloc>(context)
                        .add(DeleteProduct(products[index]));
                    Navigator.pushNamed(context, ProductsRoute,
                        arguments: FormArguments(
                            'product deleted', authenticate, catalog));
                  }
                },
                child: ListTile(
                  //return  ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: products[index]?.image != null
                        ? Image.memory(products[index]?.image)
                        : Text(products[index]?.productName != null
                            ? products[index]?.productName[0]
                            : '?'),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text("${products[index].productName}, "
                              "[${products[index].productId}]")),
                      Expanded(
                          child: Text("${products[index].description}",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("${products[index].price}",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(
                              "${products[index].categoryName}"
                              "[${products[index].categoryId}]",
                              textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              );
            },
            childCount: products == null ? 0 : products?.length,
          ),
        ),
      ],
    );
  }
}
