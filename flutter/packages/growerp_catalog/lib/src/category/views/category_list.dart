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
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_catalog.dart';
import 'category_list_styled_data.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  CategoriesListState createState() => CategoriesListState();
}

class CategoriesListState extends State<CategoryList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late CategoryBloc _categoryBloc;
  List<Category> categories = const <Category>[];
  late double bottom;
  double? right;
  CatalogLocalizations? _localizations;
  String searchString = '';
  bool _isLoading = true;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _categoryBloc = context.read<CategoryBloc>()
      ..add(const CategoryFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CatalogLocalizations.of(context);
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = categories.map((category) {
        final index = categories.indexOf(category);
        return getCategoryListRow(
          context: context,
          category: category,
          index: index,
          bloc: _categoryBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getCategoryListColumns(context),
        rows: rows,
        isLoading: _isLoading && categories.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('categoryItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _categoryBloc,
                  child: CategoryDialog(categories[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state.status == CategoryStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CategoryStatus.success) {
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
        // Update loading state
        _isLoading = state.status == CategoryStatus.loading;

        if (state.status == CategoryStatus.failure) {
          return FatalErrorForm(
            message: _localizations!.fetchCategoriesError(state.message ?? ''),
          );
        }

        categories = state.categories;
        if (categories.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search categories...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _categoryBloc.add(
                  CategoryFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom) {
      _categoryBloc.add(CategoryFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
