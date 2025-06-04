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

// ignore_for_file: exhaustive_cases
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../common/common.dart';
import '../company_user.dart';
import 'company_dialog.dart';
import 'user_dialog.dart';

class CompanyUserList extends StatefulWidget {
  const CompanyUserList({required this.role, super.key});
  final Role? role;

  @override
  CompanyUserListState createState() => CompanyUserListState();
}

class CompanyUserListState extends State<CompanyUserList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late CompanyUserBloc _companyUserBloc;
  List<CompanyUser> companiesUsers = const <CompanyUser>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  late bool isPhone;
  int limit = (WidgetsBinding
              .instance.platformDispatcher.views.first.physicalSize.height /
          35)
      .toInt();
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    switch (widget.role) {
      case Role.supplier:
        _companyUserBloc =
            context.read<CompanyUserSupplierBloc>() as CompanyUserBloc;
        break;
      case Role.customer:
        _companyUserBloc =
            context.read<CompanyUserCustomerBloc>() as CompanyUserBloc;
        break;
      case Role.lead:
        _companyUserBloc =
            context.read<CompanyUserLeadBloc>() as CompanyUserBloc;
        break;
      default:
        _companyUserBloc = context.read<CompanyUserBloc>();
    }
    _companyUserBloc.add(CompanyUserFetch(refresh: true, limit: limit));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    right = right ?? (isAPhone(context) ? 20 : 50);
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Builder(builder: (BuildContext context) {
      Widget tableView() {
        if (companiesUsers.isEmpty) {
          return const Center(
              heightFactor: 20,
              child: Text("no companies/users found",
                  style: TextStyle(fontSize: 20.0)));
        }
        // get table data formatted for tableView
        var (
          List<List<TableViewCell>> tableViewCells,
          List<double> fieldWidths,
          double? rowHeight
        ) = get2dTableData<CompanyUser>(getCompanyUserTableData,
            bloc: _companyUserBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: companiesUsers);
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
                  padding: companyUserPadding,
                  backgroundDecoration:
                      getCompanyUserBackGround(context, index),
                  extent: FixedTableSpanExtent(fieldWidths[index]),
                ),
          pinnedColumnCount: 1,
          rowBuilder: (index) => index >= tableViewCells.length
              ? null
              : TableSpan(
                  padding: companyUserPadding,
                  backgroundDecoration:
                      getCompanyUserBackGround(context, index),
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
                                        return index > companiesUsers.length
                                            ? const BottomLoader()
                                            : Dismissible(
                                                key: const Key(
                                                    'companyUserItem'),
                                                direction:
                                                    DismissDirection.startToEnd,
                                                child: BlocProvider.value(
                                                    value: _companyUserBloc,
                                                    child: companiesUsers[
                                                                    index - 1]
                                                                .type ==
                                                            PartyType.company
                                                        ? ShowCompanyDialog(
                                                            companiesUsers[
                                                                    index - 1]
                                                                .getCompany()!)
                                                        : ShowUserDialog(
                                                            companiesUsers[
                                                                    index - 1]
                                                                .getUser()!)));
                                      }))
                    }),
          pinnedRowCount: 1,
        );
      }

      blocListener(context, state) {
        if (state.status == CompanyUserStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CompanyUserStatus.success) {
          HelperFunctions.showMessage(
              context,
              '${state.message}',
              state.message != null && state.message.contains('However')
                  ? Colors.yellow
                  : Colors.green,
              seconds: 5);
        }
      }

      blocBuilder(context, state) {
        if (state.status == CompanyUserStatus.failure ||
            state.status == CompanyUserStatus.success) {
          companiesUsers = state.companiesUsers;
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "companUserBtn1",
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return const SearchCompanyUserList();
                                }).then((value) async => value == null
                                ? const SizedBox.shrink()
                                : await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BlocProvider.value(
                                          value: _companyUserBloc,
                                          child: value.type == PartyType.company
                                              ? ShowCompanyDialog(
                                                  value.getCompany()!)
                                              : ShowUserDialog(
                                                  value.getUser()!));
                                    }));
                          },
                          child: const Icon(Icons.search)),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                          key: const Key("addNewCompany"),
                          heroTag: "companUserBtn2",
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child: CompanyDialog(
                                        Company(
                                            partyId: '_NEW_',
                                            role: widget.role),
                                        dialog: true,
                                      ));
                                });
                          },
                          tooltip: 'Add New',
                          child: const Column(
                            children: [Icon(Icons.add), Text('Org')],
                          )),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                          key: const Key("addNewUser"),
                          heroTag: "companUserBtn3",
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child:
                                          UserDialog(User(role: widget.role)));
                                });
                          },
                          tooltip: 'Add New',
                          child: const Column(
                            children: [Icon(Icons.add), Text('Person')],
                          )),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                          heroTag: 'companyUserFiles',
                          key: const Key("upDownload"),
                          onPressed: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child: const CompanyUserFilesDialog());
                                });
                          },
                          tooltip: 'companies/users up/download',
                          child: const Icon(Icons.file_copy)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return const LoadingIndicator();
      }

      switch (widget.role) {
        case Role.lead:
          return BlocConsumer<CompanyUserLeadBloc, CompanyUserState>(
              listener: blocListener, builder: blocBuilder);
        case Role.customer:
          return BlocConsumer<CompanyUserCustomerBloc, CompanyUserState>(
              listener: blocListener, builder: blocBuilder);
        case Role.supplier:
          return BlocConsumer<CompanyUserSupplierBloc, CompanyUserState>(
              listener: blocListener, builder: blocBuilder);
        default:
          return BlocConsumer<CompanyUserBloc, CompanyUserState>(
              listener: blocListener, builder: blocBuilder);
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
      _companyUserBloc.add(CompanyUserFetch(limit: limit));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
