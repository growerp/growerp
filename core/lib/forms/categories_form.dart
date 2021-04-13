import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '@forms.dart';

class CategoriesForm extends StatefulWidget {
  const CategoriesForm();
  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<CategoriesForm> {
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  late CategoryBloc _categoryBloc;
  Authenticate? authenticate;
  _CategoriesState();
  late int limit;
  late bool search;
  String? searchString;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _categoryBloc = BlocProvider.of<CategoryBloc>(context)
      ..add(FetchCategory());
    search = false;
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      limit = (MediaQuery.of(context).size.height / 35).round();
    });
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        return BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
          if (state is CategoryProblem)
            return Center(child: Text("${state.errorMessage}"));
          if (state is CategorySuccess) {
            List<ProductCategory>? categories = state.categories;
            return ListView.builder(
              itemCount: state.hasReachedMax! && categories!.isNotEmpty
                  ? categories.length + 1
                  : categories!.length + 2,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0)
                  return ListTile(
                      onTap: (() {
                        setState(() {
                          search = !search;
                        });
                      }),
                      leading:
                          Image.asset('assets/images/search.png', height: 30),
                      title: search
                          ? Row(children: <Widget>[
                              SizedBox(
                                  width: ResponsiveWrapper.of(context)
                                          .isSmallerThan(TABLET)
                                      ? MediaQuery.of(context).size.width - 250
                                      : MediaQuery.of(context).size.width - 350,
                                  child: TextField(
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
                                      _categoryBloc.add(FetchCategory(
                                          search: value, limit: limit));
                                      setState(() {
                                        search = !search;
                                      });
                                    }),
                                  )),
                              ElevatedButton(
                                  child: Text('Search'),
                                  onPressed: () {
                                    _categoryBloc.add(FetchCategory(
                                        search: searchString, limit: limit));
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
                                    child: Text("Nbr.of Products",
                                        textAlign: TextAlign.center)),
                              ]),
                              Divider(color: Colors.black),
                            ]),
                      trailing: Text(' '));
                if (index == 1 && categories.isEmpty)
                  return Center(
                      heightFactor: 20,
                      child: Text("no records found!",
                          textAlign: TextAlign.center));
                index -= 1;
                return index >= categories.length
                    ? BottomLoader()
                    : Dismissible(
                        key: Key(categories[index].categoryId!),
                        direction: DismissDirection.startToEnd,
                        child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: categories[index].image != null
                                  ? Image.memory(
                                      categories[index].image!,
                                      height: 100,
                                    )
                                  : Text(
                                      "${categories[index].categoryName![0]}"),
                            ),
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                        "${categories[index].categoryName}"
                                        "[${categories[index].categoryId}]")),
                                if (!ResponsiveWrapper.of(context)
                                    .isSmallerThan(TABLET))
                                  Expanded(
                                      child: Text(
                                          "${categories[index].description}",
                                          textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(
                                        "${categories[index].nbrOfProducts} ",
                                        textAlign: TextAlign.center)),
                              ],
                            ),
                            onTap: () async {
                              dynamic result = await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CategoryDialog(
                                        formArguments: FormArguments(
                                            object: categories[index]));
                                  });
                              setState(() {
                                if (result is ProductCategory)
                                  categories
                                      .replaceRange(index, index + 1, [result]);
                              });
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.delete_forever),
                              onPressed: () {
                                _categoryBloc
                                    .add(DeleteCategory(categories[index]));
                              },
                            )));
              },
            );
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
    if (maxScroll - currentScroll <= _scrollThreshold) {
      _categoryBloc.add(FetchCategory(
          companyPartyId: authenticate!.company!.partyId,
          limit: limit,
          search: searchString));
    }
  }
}
