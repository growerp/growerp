/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../liner_type.dart';

class LinerTypeList extends StatefulWidget {
  const LinerTypeList({super.key});

  @override
  LinerTypeListState createState() => LinerTypeListState();
}

class LinerTypeListState extends State<LinerTypeList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late LinerTypeBloc _linerTypeBloc;
  List<LinerType> linerTypes = const <LinerType>[];
  late int limit;
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _linerTypeBloc = context.read<LinerTypeBloc>()
      ..add(const LinerTypesFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    Widget tableView() {
      final rows = linerTypes.map((linerType) {
        final index = linerTypes.indexOf(linerType);
        return getLinerTypeListRow(
          context: context,
          linerType: linerType,
          index: index,
          bloc: _linerTypeBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getLinerTypeListColumns(context),
        rows: rows,
        isLoading: _isLoading && linerTypes.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('linerTypeItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _linerTypeBloc,
                  child: LinerTypeDialog(linerTypes[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<LinerTypeBloc, LinerTypeState>(
      listener: (context, state) {
        if (state.status == LinerTypeStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
        if (state.status == LinerTypeStatus.success) {
          _isLoading = false;
        }
      },
      builder: (context, state) {
        linerTypes = state.linerTypes;
        return Stack(
          children: [
            tableView(),
            Positioned(
              bottom: bottom,
              right: right,
              child: FloatingActionButton(
                heroTag: 'linerTypeAdd',
                key: const Key('addNew'),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return BlocProvider.value(
                        value: _linerTypeBloc,
                        child: LinerTypeDialog(LinerType()),
                      );
                    },
                  );
                },
                tooltip: 'Add Liner Type',
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom) {
      _linerTypeBloc.add(LinerTypesFetch(limit: limit));
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}
