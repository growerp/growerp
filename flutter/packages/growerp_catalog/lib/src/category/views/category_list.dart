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

import '../../../growerp_catalog.dart';

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
  late double bottom;
  double? right;
  CatalogLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _categoryBloc = context.read<CategoryBloc>()
      ..add(const CategoryFetch(refresh: true));
    bottom = 50;
  }

  Widget tableView() {
    const Key('listView');
    if (categories.isEmpty) {
      return Center(
        child: Text(
          _localizations!.noCategories,
          style: const TextStyle(fontSize: 20.0),
        ),
      );
    }
    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight,
    ) = get2dTableData<Category>(
      getCategoryTableData,
      bloc: _categoryBloc,
      classificationId: 'AppAdmin',
      context: context,
      items: categories,
    );
    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      verticalDetails: ScrollableDetails.vertical(
        controller: _scrollController,
      ),
      horizontalDetails: ScrollableDetails.horizontal(
        controller: _horizontalController,
      ),
      cellBuilder: (context, vicinity) =>
          tableViewCells[vicinity.row][vicinity.column],
      columnBuilder: (index) => index >= tableViewCells[0].length
          ? null
          : TableSpan(
              padding: categoryPadding,
              backgroundDecoration: getCategoryBackGround(context, index),
              extent: FixedTableSpanExtent(fieldWidths[index]),
            ),
      pinnedColumnCount: 1,
      rowBuilder: (index) => index >= tableViewCells.length
          ? null
          : TableSpan(
              padding: categoryPadding,
              backgroundDecoration: getCategoryBackGround(context, index),
              extent: FixedTableSpanExtent(rowHeight!),
              recognizerFactories: <Type, GestureRecognizerFactory>{
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                      (TapGestureRecognizer t) => t.onTap = () => showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return index > categories.length
                              ? const BottomLoader()
                              : Dismissible(
                                  key: const Key('dummy'),
                                  direction: DismissDirection.startToEnd,
                                  child: BlocProvider.value(
                                    value: _categoryBloc,
                                    child: CategoryDialog(
                                      categories[index - 1],
                                    ),
                                  ),
                                );
                        },
                      ),
                    ),
              },
            ),
      pinnedRowCount: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CatalogLocalizations.of(context);
    right = right ?? (isAPhone(context) ? 20 : 50);
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state.status == CategoryStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CategoryStatus.success) {
          started = true;
          final translatedMessage = state.message != null
              ? translateCategoryBlocMessage(state.message!, _localizations!)
              : '';
          if (translatedMessage.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              translatedMessage,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case CategoryStatus.failure:
            return Center(
              child: Text(
                _localizations!.fetchCategoriesError(state.message ?? ''),
              ),
            );
          case CategoryStatus.success:
            categories = state.categories;
            return Stack(
              children: [
                tableView(),
                Positioned(
                  right: right,
                  bottom: bottom,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        right = right! - details.delta.dx;
                        bottom -= details.delta.dy;
                      });
                    },
                    child: Column(
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
                                // search separate
                                return BlocProvider.value(
                                  value: context
                                      .read<DataFetchBloc<Locations>>(),
                                  child: const SearchCategoryList(),
                                );
                              },
                            ).then(
                              (value) async => value != null && context.mounted
                                  ?
                                    // show detail page
                                    await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _categoryBloc,
                                          child: CategoryDialog(value),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                          child: const Icon(Icons.search),
                        ),
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
                                    child: const CategoryFilesDialog(),
                                  ),
                            );
                          },
                          tooltip: _localizations!.categoryUpDown,
                          child: const Icon(Icons.file_copy),
                        ),
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
                                  child: CategoryDialog(Category()),
                                );
                              },
                            );
                          },
                          tooltip: _localizations!.addNew,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
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
