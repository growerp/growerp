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

import '../category.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  CategoriesListState createState() => CategoriesListState();
}

class CategoriesListState extends State<CategoryList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late bool search;
  late CategoryBloc _categoryBloc;
  late bool started;
  late List<Category> categories;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _categoryBloc = context.read<CategoryBloc>();
    _categoryBloc.add(const CategoryFetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
        listenWhen: (previous, current) =>
            previous.status == CategoryStatus.loading,
        listener: (context, state) {
          if (state.status == CategoryStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == CategoryStatus.success) {
            started = true;
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case CategoryStatus.failure:
              return Center(
                  child: Text('failed to fetch categories: ${state.message}'));
            case CategoryStatus.success:
              categories = state.categories;

              Widget tableView() {
                if (categories.isEmpty) {
                  return const Center(
                      heightFactor: 20,
                      child: Text("no categories found",
                          textAlign: TextAlign.center));
                }
                // get table data formatted for tableView
                var (
                  List<List<TableViewCell>> tableViewCells,
                  List<double> fieldWidths,
                  double? rowHeight
                ) = get2dTableData<Category>(getCategoryTableData,
                    bloc: _categoryBloc,
                    classificationId: 'AppAdmin',
                    context: context,
                    items: categories);
                return TableView.builder(
                  diagonalDragBehavior: DiagonalDragBehavior.free,
                  verticalDetails:
                      ScrollableDetails.vertical(controller: _scrollController),
                  horizontalDetails: ScrollableDetails.horizontal(
                      controller: _horizontalController),
                  cellBuilder: (context, vicinity) =>
                      tableViewCells[vicinity.row][vicinity.column],
                  columnBuilder: (index) => index >= tableViewCells[0].length
                      ? null
                      : TableSpan(
                          padding: categoryPadding,
                          backgroundDecoration:
                              getCategoryBackGround(context, index),
                          extent: FixedTableSpanExtent(fieldWidths[index]),
                        ),
                  pinnedColumnCount: 1,
                  rowBuilder: (index) => index >= tableViewCells.length
                      ? null
                      : TableSpan(
                          padding: categoryPadding,
                          backgroundDecoration:
                              getCategoryBackGround(context, index),
                          extent: FixedTableSpanExtent(rowHeight!),
                          recognizerFactories: <Type, GestureRecognizerFactory>{
                              TapGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                          TapGestureRecognizer>(
                                      () => TapGestureRecognizer(),
                                      (TapGestureRecognizer t) =>
                                          t.onTap = () => showDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return index >
                                                        state.categories.length
                                                    ? const BottomLoader()
                                                    : Dismissible(
                                                        key: const Key(
                                                            'locationItem'),
                                                        direction:
                                                            DismissDirection
                                                                .startToEnd,
                                                        child: BlocProvider.value(
                                                            value:
                                                                _categoryBloc,
                                                            child: CategoryDialog(
                                                                categories[
                                                                    index -
                                                                        1])));
                                              }))
                            }),
                  pinnedRowCount: 1,
                );
              }

              return Scaffold(
                  floatingActionButton: Column(
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
                                        value: context
                                            .read<DataFetchBloc<Locations>>(),
                                        child: const SearchCategoryList());
                                  }).then((value) async => value != null &&
                                      context.mounted
                                  ?
                                  // show detail page
                                  await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                            value: _categoryBloc,
                                            child: CategoryDialog(value));
                                      })
                                  : const SizedBox.shrink());
                            },
                            child: const Icon(Icons.search)),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                            heroTag: 'catFiles',
                            key: const Key("upDownload"),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      BlocProvider.value(
                                          value: _categoryBloc,
                                          child: const CategoryFilesDialog()));
                            },
                            tooltip: 'category up/download',
                            child: const Icon(Icons.file_copy)),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                            heroTag: 'catNew',
                            key: const Key("addNew"),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                        value: _categoryBloc,
                                        child: CategoryDialog(Category()));
                                  });
                            },
                            tooltip: 'Add New',
                            child: const Icon(Icons.add)),
                      ]),
                  body: tableView());
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
    if (_isBottom) context.read<CategoryBloc>().add(const CategoryFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
