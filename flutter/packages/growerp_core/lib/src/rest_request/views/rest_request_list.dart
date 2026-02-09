/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'rest_request_list_styled_data.dart';

class RestRequestList extends StatefulWidget {
  const RestRequestList({super.key});

  @override
  RestRequestListState createState() => RestRequestListState();
}

class RestRequestListState extends State<RestRequestList> {
  final _scrollController = ScrollController();
  final double _scrollThreshold = 100.0;
  late RestRequestBloc _restRequestBloc;
  List<RestRequest> restRequests = const <RestRequest>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  CoreLocalizations? _localizations;
  bool _isLoading = true;

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
    _localizations = CoreLocalizations.of(context);
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      final rows = restRequests.map((request) {
        final index = restRequests.indexOf(request);
        return getRestRequestListRow(
          context: context,
          request: request,
          index: index,
        );
      }).toList();

      return StyledDataTable(
        columns: getRestRequestListColumns(context),
        rows: rows,
        isLoading: _isLoading && restRequests.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return RestRequestDetailDialog(restRequest: restRequests[index]);
            },
          );
        },
      );
    }

    return BlocConsumer<RestRequestBloc, RestRequestState>(
      listener: (context, state) {
        if (state.status == RestRequestStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == RestRequestStatus.success) {
          if (state.message != null && state.message!.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        _isLoading = state.status == RestRequestStatus.loading;
        if (state.status == RestRequestStatus.failure && restRequests.isEmpty) {
          return FatalErrorForm(
            message: _localizations!.cannotLoadRestRequests,
          );
        } else {
          restRequests = state.restRequests;
          if (restRequests.isNotEmpty && currentScroll > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
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
                    tooltip: _localizations!.refresh,
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
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
