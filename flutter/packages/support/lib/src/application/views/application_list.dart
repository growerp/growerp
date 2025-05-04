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

import '../application.dart';

class ApplicationList extends StatefulWidget {
  const ApplicationList({super.key});

  @override
  ApplicationsListState createState() => ApplicationsListState();
}

class ApplicationsListState extends State<ApplicationList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late bool search;
  late ApplicationBloc _applicationBloc;
  late bool started;
  late List<Application> applications;
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _applicationBloc = context.read<ApplicationBloc>()
      ..add(const ApplicationFetch(refresh: true));
    bottom = 50;
  }

  Widget tableView() {
    if (applications.isEmpty) {
      return const Center(
          child: Text("No applications yet, add one with '+'",
              style: TextStyle(fontSize: 20.0)));
    }
    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight
    ) = get2dTableData<Application>(getApplicationTableData,
        bloc: _applicationBloc,
        context: context,
        items: applications,
        classificationId: 'AppAdmin');
    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      verticalDetails:
          ScrollableDetails.vertical(controller: _scrollController),
      horizontalDetails:
          ScrollableDetails.horizontal(controller: _horizontalController),
      cellBuilder: (context, vicinity) =>
          tableViewCells[vicinity.row][vicinity.column],
      columnBuilder: (index) => index >= tableViewCells[0].length
          ? null
          : TableSpan(
              padding: applicationPadding,
              backgroundDecoration: getApplicationBackGround(context, index),
              extent: FixedTableSpanExtent(fieldWidths[index]),
            ),
      pinnedColumnCount: 1,
      rowBuilder: (index) => index >= tableViewCells.length
          ? null
          : TableSpan(
              padding: applicationPadding,
              backgroundDecoration: getApplicationBackGround(context, index),
              extent: FixedTableSpanExtent(rowHeight!),
              recognizerFactories: <Type, GestureRecognizerFactory>{
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                          TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                      (TapGestureRecognizer t) => t.onTap = () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return index > applications.length
                                ? const BottomLoader()
                                : Dismissible(
                                    key: const Key('dummy'),
                                    direction: DismissDirection.startToEnd,
                                    child: BlocProvider.value(
                                        value: _applicationBloc,
                                        child: ApplicationDialog(
                                            applications[index - 1])));
                          }))
                }),
      pinnedRowCount: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    right = right ?? (isAPhone(context) ? 20 : 50);
    return BlocConsumer<ApplicationBloc, ApplicationState>(
        listenWhen: (previous, current) =>
            previous.status == ApplicationStatus.loading,
        listener: (context, state) {
          if (state.status == ApplicationStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == ApplicationStatus.success) {
            started = true;
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case ApplicationStatus.failure:
              return Center(
                  child:
                      Text('failed to fetch applications: ${state.message}'));
            case ApplicationStatus.success:
              applications = state.applications;
              return tableView();
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
    if (_isBottom) {
      context.read<ApplicationBloc>().add(const ApplicationFetch());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
