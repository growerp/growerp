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

import '../liner_panel.dart';

/// Inline panel list for embedding inside a WorkOrder dialog.
/// Pass [workEffortId] to filter panels for a specific work order.
class LinerPanelList extends StatefulWidget {
  final String? workEffortId;
  final String? salesOrderId;
  const LinerPanelList({super.key, this.workEffortId, this.salesOrderId});

  @override
  LinerPanelListState createState() => LinerPanelListState();
}

class LinerPanelListState extends State<LinerPanelList> {
  final _scrollController = ScrollController();
  late LinerPanelBloc _linerPanelBloc;
  List<LinerPanel> linerPanels = const <LinerPanel>[];
  late double bottom;
  double? right;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _linerPanelBloc = context.read<LinerPanelBloc>()
      ..add(LinerPanelsFetch(
        workEffortId: widget.workEffortId,
        salesOrderId: widget.salesOrderId,
        refresh: true,
      ));
    bottom = 20;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 10 : 20);

    Widget tableView() {
      final rows = linerPanels.map((linerPanel) {
        final index = linerPanels.indexOf(linerPanel);
        return getLinerPanelListRow(
          context: context,
          linerPanel: linerPanel,
          index: index,
          bloc: _linerPanelBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getLinerPanelListColumns(context),
        rows: rows,
        isLoading: _isLoading && linerPanels.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 48,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('linerPanelItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _linerPanelBloc,
                  child: LinerPanelDialog(linerPanels[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<LinerPanelBloc, LinerPanelState>(
      listener: (context, state) {
        if (state.status == LinerPanelStatus.failure) {
          HelperFunctions.showMessage(
            context,
            'Error: ${state.message}',
            Colors.red,
          );
        }
        if (state.status == LinerPanelStatus.success) {
          _isLoading = false;
        }
      },
      builder: (context, state) {
        linerPanels = state.linerPanels;
        return Stack(
          children: [
            tableView(),
            Positioned(
              bottom: bottom,
              right: right,
              child: FloatingActionButton.small(
                heroTag: 'linerPanelAdd',
                key: const Key('addPanel'),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return BlocProvider.value(
                        value: _linerPanelBloc,
                        child: LinerPanelDialog(
                          LinerPanel(
                            workEffortId: widget.workEffortId,
                            salesOrderId: widget.salesOrderId,
                          ),
                        ),
                      );
                    },
                  );
                },
                tooltip: 'Add Panel',
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
