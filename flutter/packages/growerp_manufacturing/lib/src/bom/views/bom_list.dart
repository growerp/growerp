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

import '../bom.dart';

class BomList extends StatefulWidget {
  const BomList({super.key});

  @override
  BomListState createState() => BomListState();
}

class BomListState extends State<BomList> {
  final _scrollController = ScrollController();
  late BomBloc _bomBloc;
  List<Bom> boms = const <Bom>[];
  late int limit;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bomBloc = context.read<BomBloc>();
    _bomBloc.add(const BomsFetch(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    return BlocConsumer<BomBloc, BomState>(
      listener: (context, state) {
        if (state.status == BomStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
        if (state.status == BomStatus.success) {
          _isLoading = false;
        }
      },
      builder: (context, state) {
        boms = state.boms;
        final rows = boms.asMap().entries.map((e) {
          return getBomHeaderRow(
            context: context,
            bom: e.value,
            index: e.key,
          );
        }).toList();

        return Stack(
          children: [
            StyledDataTable(
              columns: getBomHeaderColumns(context),
              rows: rows,
              isLoading: _isLoading && boms.isEmpty,
              scrollController: _scrollController,
              rowHeight: isPhone ? 72 : 56,
              onRowTap: (index) {
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext ctx) => BlocProvider.value(
                    value: _bomBloc,
                    child: BomDialog(bom: boms[index]),
                  ),
                ).then((_) => _bomBloc.add(const BomsFetch(refresh: true)));
              },
            ),
            Positioned(
              bottom: 50,
              right: right,
              child: FloatingActionButton(
                heroTag: 'bomAdd',
                key: const Key('addNew'),
                tooltip: 'New BOM',
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext ctx) => BlocProvider.value(
                      value: _bomBloc,
                      child: const BomDialog(),
                    ),
                  ).then((_) => _bomBloc.add(const BomsFetch(refresh: true)));
                },
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
      _bomBloc.add(BomsFetch(limit: limit));
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}
