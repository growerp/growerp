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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:growerp_models/growerp_models.dart';

class RestRequestList extends StatefulWidget {
  const RestRequestList({super.key});

  @override
  RestRequestListState createState() => RestRequestListState();
}

class RestRequestListState extends State<RestRequestList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late RestRequestBloc _restRequestBloc;
  List<RestRequest> restRequests = const <RestRequest>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _restRequestBloc = context.read<RestRequestBloc>()
      ..add(const RestRequestFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (restRequests.isEmpty) {
            return const Center(
              child: Text(
                'No REST requests found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }
          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<RestRequest>(
            getRestRequestListTableData,
            bloc: _restRequestBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: restRequests,
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
                    padding: const SpanPadding(trailing: 5, leading: 5),
                    backgroundDecoration: _getTableBackGround(context, index),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: const SpanPadding(trailing: 5, leading: 5),
                    backgroundDecoration: _getTableBackGround(context, index),
                    extent: FixedTableSpanExtent(rowHeight!),
                    recognizerFactories: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            TapGestureRecognizer
                          >(
                            () => TapGestureRecognizer(),
                            (TapGestureRecognizer t) => t.onTap = () =>
                                showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return index > restRequests.length
                                        ? const BottomLoader()
                                        : RestRequestDetailDialog(
                                            restRequest:
                                                restRequests[index - 1],
                                          );
                                  },
                                ),
                          ),
                    },
                  ),
            pinnedRowCount: 1,
          );
        }

        return BlocConsumer<RestRequestBloc, RestRequestState>(
          listener: (context, state) {
            if (state.status == RestRequestStatus.failure) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.red,
              );
            }
            if (state.status == RestRequestStatus.success) {
              HelperFunctions.showMessage(
                context,
                '${state.message}',
                Colors.green,
              );
            }
          },
          builder: (context, state) {
            if (state.status == RestRequestStatus.failure) {
              return const FatalErrorForm(
                message: "Could not load REST requests!",
              );
            } else {
              restRequests = state.restRequests;
              if (restRequests.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollController.jumpTo(currentScroll),
                  );
                });
              }
              hasReachedMax = state.hasReachedMax;
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
                      child: FloatingActionButton(
                        key: const Key("refresh"),
                        heroTag: "restRequestBtn1",
                        onPressed: () {
                          _restRequestBloc.add(
                            const RestRequestFetch(refresh: true),
                          );
                        },
                        tooltip: 'Refresh',
                        child: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  SpanDecoration? _getTableBackGround(BuildContext context, int index) {
    if (index == 0) {
      return SpanDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
      );
    }
    return null;
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _restRequestBloc.add(const RestRequestFetch());
    }
  }
}
