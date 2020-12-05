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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/forms/@forms.dart';
import 'package:models/models.dart';
import 'package:core/helper_functions.dart';
import '../routing_constants.dart';

class HomeForm extends StatefulWidget {
  final String message;

  const HomeForm([this.message]);
  @override
  State<HomeForm> createState() => _HomeState(message);
}

class _HomeState extends State<HomeForm> {
  final String message;
  Authenticate authenticate;
  List<Product> products;
  List<ProductCategory> categories;
  String selectedCategoryId;

  _HomeState([this.message]);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthProblem) {
        return Container(
            child: Center(
                child: Text("${state.errorMessage}",
                    style:
                        new TextStyle(fontSize: 18.0, color: Colors.black))));
      }
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      if (state is AuthUnauthenticated) authenticate = state.authenticate;
      return Scaffold(
          appBar: AppBar(
              title: Text("${authenticate?.company?.name ?? 'Company??'} " +
                  "${authenticate?.apiKey != null ? "- username: " + authenticate?.user?.name : ''}"),
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.settings),
                    tooltip: 'Settings',
                    onPressed: () async {
                      await _settingsDialog(context, authenticate);
                    }),
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  tooltip: 'Cart',
                  onPressed: () => Navigator.pushNamed(context, CartRoute),
                ),
                if (authenticate?.apiKey == null)
                  IconButton(
                      icon: Icon(Icons.exit_to_app),
                      tooltip: 'Login',
                      onPressed: () async {
                        if (await Navigator.pushNamed(context, LoginRoute) ==
                            true) {
                          Navigator.popAndPushNamed(context, HomeRoute,
                              arguments: 'Login Successful');
                        }
                      }),
                if (authenticate?.apiKey != null)
                  IconButton(
                      icon: Icon(Icons.do_not_disturb),
                      tooltip: 'Logout',
                      onPressed: () => {
                            BlocProvider.of<AuthBloc>(context).add(Logout()),
                            Future<Null>.delayed(Duration(milliseconds: 300),
                                () {
                              Navigator.popAndPushNamed(context, HomeRoute,
                                  arguments: 'Logout successful');
                            })
                          })
              ]),
          body: BlocConsumer<CatalogBloc, CatalogState>(
              listener: (context, state) {
            if (state is CatalogProblem) {
              HelperFunctions.showMessage(
                  context, '${state.errorMessage}', Colors.green);
            }
            if (state is CatalogLoading) {
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
            }
          }, builder: (context, state) {
            if (state is CatalogLoaded) {
              categories = state.catalog?.categories;
              selectedCategoryId ??= categories != null && categories.length > 0
                  ? categories[0]?.categoryId
                  : null;
              products = state.catalog?.products;
            } else
              return SplashForm();
/*            return Container(
                child: Center(
                    child: Text("screen text",
                        style: new TextStyle(
                            fontSize: 18.0, color: Colors.black))));
*/
            return SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: ListView(shrinkWrap: true, children: <Widget>[
                  _categoryList(),
                  _productsGrid(),
                ]));
          }));
    });
  }

  Widget _categoryList() {
    if (categories == null || categories.length == 0) {
      return Center(
        child: Text("No categories found to display",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      );
    } else
      return Container(
          height: 110,
          alignment: Alignment.centerLeft,
          child: ListView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: categories?.length,
              itemBuilder: (context, index) {
                var data = categories[index];
                return Column(children: <Widget>[
                  GestureDetector(
                    onTap: () =>
                        setState(() => selectedCategoryId = data.categoryId),
                    child: Container(
                      margin: EdgeInsets.all(10),
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      child: data.image != null
                          ? Image.memory(
                              data.image,
                              height: 40,
                              width: 40,
                            )
                          : Image.asset('assets/images/default.png'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 5),
                            blurRadius: 30,
                          )
                        ],
                      ),
                    ),
                  ),
                  Row(children: <Widget>[
                    Text(data.categoryName),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 14,
                    )
                  ])
                ]);
              }));
  }

  Widget _productsGrid() {
    Size size = MediaQuery.of(context).size;
    double screenWidth = size.width;
    double screenHeight = size.height;
    if (products == null || products.length == 0)
      return Center(
        child: Text("No products found to display",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      );
    else {
      List<Product> productList =
          products.where((i) => i.categoryId == selectedCategoryId).toList();
      return ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          child: Container(
              height: screenHeight - 200,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Color(0xffECE9DE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Stack(children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 50, bottom: 5),
                  width: screenWidth,
                  child: StaggeredGridView.countBuilder(
                    crossAxisCount: 4,
                    itemCount: productList.length,
                    itemBuilder: (BuildContext context, int index) =>
                        new Container(
                            margin: EdgeInsets.only(
                              left: index % 2 == 0 ? 10 : 0,
                              right: index % 2 == 0 ? 0 : 10,
                            ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25)),
                            child: Center(
                              child: _gridItem(productList[index]),
                            )),
                    staggeredTileBuilder: (int index) =>
                        new StaggeredTile.count(2, index == 0 ? 2 : 3),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                ),
                _customTitle(categories != null && categories.length > 0
                    ? categories
                        .firstWhere((i) => i.categoryId == selectedCategoryId)
                        .categoryName
                    : '')
              ])));
    }
  }

  Widget _gridItem(product) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, ProductEcomRoute, arguments: product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
              child: Hero(
            tag: '${product.productId}',
            child: product.image != null
                ? Image.memory(
                    product.image,
                    height: 125,
                    fit: BoxFit.contain,
                  )
                : Image.asset('assets/images/default.png'),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text("${product.price.toString()} ",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "${product.productName}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text('${product.description}'),
          )
        ],
      ),
    );
  }

  Widget _customTitle(title) {
    Size size = MediaQuery.of(context).size;
    double screenWidth = size.width;

    return Container(
      width: screenWidth,
      height: 60,
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Center(
        child: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: <Color>[
          Color(0xffECE9DE),
          Color(0xffefebe9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      )),
    );
  }
}

_settingsDialog(BuildContext context, Authenticate authenticate) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          title: Text('Settings', textAlign: TextAlign.center),
          content: Container(
            height: 200,
            child: Column(children: <Widget>[
              RaisedButton(
                child: Text('Select an another company'),
                onPressed: () async {
                  authenticate.company.partyId = null;
                  BlocProvider.of<AuthBloc>(context)
                      .add(UpdateAuth(authenticate));
                  await Navigator.popAndPushNamed(context, LoginRoute);
                },
              ),
              SizedBox(height: 20),
              Visibility(
                  visible: authenticate.apiKey == null,
                  child: RaisedButton(
                    child: Text('Register as a customer'),
                    onPressed: () {
                      Navigator.popAndPushNamed(context, RegisterRoute);
                    },
                  )),
              SizedBox(height: 20),
              RaisedButton(
                child: Text('About'),
                onPressed: () {
                  Navigator.popAndPushNamed(context, AboutRoute);
                },
              ),
            ]),
          ));
    },
  );
}
