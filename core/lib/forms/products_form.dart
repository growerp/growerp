import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:core/helper_functions.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '@forms.dart';

class ProductsForm extends StatefulWidget {
  const ProductsForm();
  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<ProductsForm> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late ProductBloc _productBloc;
  Authenticate authenticate = Authenticate();
  List<Product> products = const <Product>[];
  late int limit;
  late bool search;
  late String classificationId;
  String? searchString;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _productBloc = BlocProvider.of<ProductBloc>(context);
    search = false;
    classificationId = GlobalConfiguration().get("classificationId");
    _productBloc..add(FetchProduct(limit: 20));
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 35).round();
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        return BlocConsumer<ProductBloc, ProductState>(
            listener: (context, state) {
          if (state is ProductProblem)
            HelperFunctions.showMessage(
                context, '${state.errorMessage}', Colors.red);
          if (state is ProductSuccess)
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
        }, builder: (context, state) {
          if (state is ProductSuccess) {
            products = state.products;
            _searchController.text = state.searchString ?? '';
            return RefreshIndicator(
                onRefresh: (() async {
                  _productBloc.add(FetchProduct(refresh: true));
                }),
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: state.hasReachedMax && products.isNotEmpty
                      ? products.length + 1
                      : products.length + 2,
                  controller: _scrollController,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0)
                      return ListTile(
                          onTap: (() {
                            setState(() {
                              search = !search;
                            });
                          }),
                          leading: Image.asset('assets/images/search.png',
                              height: 30),
                          title: search
                              ? Row(children: <Widget>[
                                  SizedBox(
                                      width: ResponsiveWrapper.of(context)
                                              .isSmallerThan(TABLET)
                                          ? MediaQuery.of(context).size.width -
                                              250
                                          : MediaQuery.of(context).size.width -
                                              350,
                                      child: TextField(
                                        controller: _searchController,
                                        textInputAction: TextInputAction.go,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent),
                                          ),
                                          hintText:
                                              "search in ID, name and description...",
                                        ),
                                        onChanged: ((value) {
                                          searchString = value;
                                        }),
                                        onSubmitted: ((value) {
                                          _productBloc.add(FetchProduct(
                                              companyPartyId:
                                                  authenticate.company!.partyId,
                                              search: value,
                                              limit: limit));
                                          setState(() {
                                            search = !search;
                                          });
                                        }),
                                      )),
                                  ElevatedButton(
                                      child: Text('Search'),
                                      onPressed: () {
                                        _productBloc.add(FetchProduct(
                                            companyPartyId:
                                                authenticate.company!.partyId,
                                            search: searchString,
                                            limit: limit));
                                      })
                                ])
                              : Column(children: [
                                  Row(children: <Widget>[
                                    Expanded(
                                        child: Text("Name[ID]",
                                            textAlign: TextAlign.center)),
                                    if (!ResponsiveWrapper.of(context)
                                        .isSmallerThan(TABLET))
                                      Expanded(
                                          child: Text("Description",
                                              textAlign: TextAlign.center)),
                                    Expanded(
                                        child: Text("Price",
                                            textAlign: TextAlign.center)),
                                    if (classificationId != 'AppHotel')
                                      Expanded(
                                          child: Text("Category",
                                              textAlign: TextAlign.center)),
                                    Expanded(
                                        child: Text(
                                            classificationId != 'AppHotel'
                                                ? "Nbr Of Assets"
                                                : "Number of Rooms",
                                            textAlign: TextAlign.center)),
                                  ]),
                                  Divider(color: Colors.black),
                                ]),
                          trailing: Text(' '));
                    if (index == 1 && products.isEmpty)
                      return Center(
                          heightFactor: 20,
                          child: Text("no records found!",
                              textAlign: TextAlign.center));
                    index -= 1;
                    return index >= products.length
                        ? BottomLoader()
                        : Dismissible(
                            key: Key(products[index].productId!),
                            direction: DismissDirection.startToEnd,
                            child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: products[index].image != null
                                      ? Image.memory(
                                          products[index].image!,
                                          height: 100,
                                        )
                                      : Text(
                                          "${products[index].productName![0]}"),
                                ),
                                title: Row(
                                  children: <Widget>[
                                    Expanded(
                                        child: Text(
                                            "${products[index].productName}"
                                            "[${products[index].productId}]")),
                                    if (!ResponsiveWrapper.of(context)
                                        .isSmallerThan(TABLET))
                                      Expanded(
                                          child: Text(
                                              "${products[index].description}",
                                              textAlign: TextAlign.center)),
                                    Expanded(
                                        child: Text(
                                            "${authenticate.company!.currencyId} "
                                            "${products[index].price}",
                                            textAlign: TextAlign.center)),
                                    if (classificationId != 'AppHotel')
                                      Expanded(
                                          child: Text(
                                              "${products[index].categoryName}",
                                              textAlign: TextAlign.center)),
                                    Expanded(
                                        child: Text(
                                            "${products[index].assetCount}",
                                            textAlign: TextAlign.center)),
                                  ],
                                ),
                                onTap: () async {
                                  await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ProductDialog(
                                            formArguments: FormArguments(
                                                object: products[index]));
                                      });
                                },
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_forever),
                                  onPressed: () {
                                    _productBloc
                                        .add(DeleteProduct(products[index]));
                                  },
                                )));
                  },
                ));
          }
          return Center(child: CircularProgressIndicator());
        });
      }
      return Container(child: Center(child: Text("Not Authorized!")));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= 200) {
      _productBloc.add(FetchProduct(
          companyPartyId: authenticate.company!.partyId,
          limit: limit,
          search: searchString));
    }
  }
}
