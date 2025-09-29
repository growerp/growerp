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
import 'package:growerp_catalog/src/l10n/activity_localizations.dart';

class SearchCategoryList extends StatefulWidget {
  const SearchCategoryList({super.key});

  @override
  SearchCategoryState createState() => SearchCategoryState();
}

class SearchCategoryState extends State<SearchCategoryList> {
  late DataFetchBloc _categoryBloc;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<DataFetchBloc<Categories>>()
      ..add(
          GetDataEvent(() => context.read<RestClient>().getCategory(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    var al = ActivityLocalizations.of(context)!;
    return BlocConsumer<DataFetchBloc<Categories>, DataFetchState<Categories>>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        return Center(
            child: Text(al.fetchSearchItemsFailed(state.message!)));
      }
      if (state.status == DataFetchStatus.success) {
        categories = (state.data as Categories).categories;
      }
      return Stack(
        children: [
          CategorySearchDialog(
              finDocBloc: _categoryBloc,
              widget: widget,
              categories: categories),
          if (state.status == DataFetchStatus.loading) const LoadingIndicator(),
        ],
      );
    });
  }
}

class CategorySearchDialog extends StatelessWidget {
  const CategorySearchDialog({
    super.key,
    required DataFetchBloc finDocBloc,
    required this.widget,
    required this.categories,
  }) : _categoryBloc = finDocBloc;

  final DataFetchBloc _categoryBloc;
  final SearchCategoryList widget;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    var al = ActivityLocalizations.of(context)!;
    final ScrollController scrollController = ScrollController();
    return Dialog(
        key: const Key('SearchDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            title: al.categorySearch,
            height: 500,
            width: 350,
            child: Column(children: [
              TextFormField(
                  key: const Key('searchField'),
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: InputDecoration(labelText: al.searchInput),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a search value?';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => _categoryBloc.add(GetDataEvent(
                      () => context
                          .read<RestClient>()
                          .getCategory(limit: 5, searchString: value)))),
              const SizedBox(height: 20),
              Text(al.searchResults),
              Expanded(
                  child: ListView.builder(
                      key: const Key('listView'),
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: categories.length + 2,
                      controller: scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Visibility(
                              visible: categories.isEmpty,
                              child: Center(
                                  heightFactor: 20,
                                  child: Text(al.noSearchItems,
                                      key: const Key('empty'),
                                      textAlign: TextAlign.center)));
                        }
                        index--;
                        return index >= categories.length
                            ? const Text('')
                            : Dismissible(
                                key: const Key('searchItem'),
                                direction: DismissDirection.startToEnd,
                                child: ListTile(
                                  title: Text(
                                      "ID: ${categories[index].pseudoId}\n"
                                      "Name: ${categories[index].categoryName}",
                                      key: Key("searchResult$index")),
                                  onTap: () => Navigator.of(context)
                                      .pop(categories[index]),
                                ));
                      }))
            ])));
  }
}