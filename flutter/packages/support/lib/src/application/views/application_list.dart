/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../application.dart';
import 'application_list_styled_data.dart';

class ApplicationList extends StatefulWidget {
  const ApplicationList({super.key});

  @override
  ApplicationsListState createState() => ApplicationsListState();
}

class ApplicationsListState extends State<ApplicationList> {
  final _scrollController = ScrollController();
  late ApplicationBloc _applicationBloc;
  late bool started;
  late List<Application> applications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _applicationBloc = context.read<ApplicationBloc>()
      ..add(const ApplicationFetch(refresh: true));
  }

  Widget tableView() {
    final isPhone = isAPhone(context);
    final rows = applications.map((application) {
      final index = applications.indexOf(application);
      return getApplicationListRow(
        context: context,
        application: application,
        index: index,
        bloc: _applicationBloc,
      );
    }).toList();

    return StyledDataTable(
      columns: getApplicationListColumns(context),
      rows: rows,
      isLoading: _isLoading && applications.isEmpty,
      scrollController: _scrollController,
      rowHeight: isPhone ? 72 : 56,
      onRowTap: (index) {
        showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return Dismissible(
              key: const Key('dummy'),
              direction: DismissDirection.startToEnd,
              child: BlocProvider.value(
                value: _applicationBloc,
                child: ApplicationDialog(applications[index]),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationBloc, ApplicationState>(
      listenWhen: (previous, current) =>
          previous.status == ApplicationStatus.loading,
      listener: (context, state) {
        if (state.status == ApplicationStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == ApplicationStatus.success) {
          started = true;
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
        _isLoading = state.status == ApplicationStatus.loading;
        switch (state.status) {
          case ApplicationStatus.failure:
            return Center(
              child: Text('failed to fetch applications: ${state.message}'),
            );
          case ApplicationStatus.success:
            applications = state.applications;
            return tableView();
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
