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

class CategoriesForm extends StatelessWidget {
  final FormArguments formArguments;
  CategoriesForm(this.formArguments);
  @override
  Widget build(BuildContext context) {
    var a = (formArguments) => (CategoriesFormHeader(formArguments.message));
    return ShowNavigationRail(a(formArguments), 4);
  }
}

class CategoriesFormHeader extends StatefulWidget {
  final String message;
  const CategoriesFormHeader(this.message);
  @override
  _CategoriesFormStateHeader createState() =>
      _CategoriesFormStateHeader(message);
}

class _CategoriesFormStateHeader extends State<CategoriesFormHeader> {
  final String message;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Authenticate authenticate;
  Catalog catalog;
  List<ProductCategory> categories;

  _CategoriesFormStateHeader(this.message) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }
  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = this.authenticate;
    Catalog catalog = this.catalog;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      return ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
              appBar: AppBar(
                  title: companyLogo(context, authenticate, 'Category List'),
                  automaticallyImplyLeading:
                      ResponsiveWrapper.of(context).isSmallerThan(TABLET)),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, CategoryRoute,
                      arguments:
                          FormArguments('Enter new category information'));
                },
                tooltip: 'Add new category',
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
                    if (state is CatalogLoading)
                      HelperFunctions.showMessage(
                          context, '${state.message}', Colors.green);
                  }, builder: (context, state) {
                    if (state is CatalogLoaded) {
                      catalog = state.catalog;
                      categories = catalog.categories;
                    }
                    return categoryList(catalog);
                  }))));
    });
  }

  Widget categoryList(catalog) {
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
                    child: Text("Category Name", textAlign: TextAlign.center)),
                Expanded(
                    child: Text("categoryId", textAlign: TextAlign.center)),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return InkWell(
                onTap: () async {
                  dynamic result = await Navigator.pushNamed(
                      context, CategoryRoute,
                      arguments: FormArguments(null, categories[index]));
                  setState(() {
                    if (result is Catalog) categories = result?.categories;
                  });
                  HelperFunctions.showMessage(
                      context,
                      'Category ${categories[index].categoryName}  modified',
                      Colors.green);
                },
                onLongPress: () async {
                  bool result = await confirmDialog(
                      context,
                      "${categories[index].categoryName}",
                      "Delete this category?");
                  if (result) {
                    BlocProvider.of<CatalogBloc>(context)
                        .add(DeleteCategory(categories[index]));
                    Navigator.pushNamed(context, CategoriesRoute,
                        arguments: FormArguments(
                            'Category deleted', authenticate, catalog));
                  }
                },
                child: ListTile(
                  //return  ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: categories[index]?.image != null
                        ? Image.memory(categories[index]?.image)
                        : Text(categories[index]?.categoryName[0]),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text("${categories[index].categoryName}, "
                              "[${categories[index].categoryId}]")),
                      Expanded(
                          child: Text("${categories[index].categoryId}",
                              textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              );
            },
            childCount: categories == null ? 0 : categories?.length,
          ),
        ),
      ],
    );
  }
}
