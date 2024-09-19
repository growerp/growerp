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

import '../../../growerp_user_company.dart';

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
  late CompanyBloc _companyBloc;
  late UserBloc _userBloc;
  List<CompanyUser> companiesUsers = const <CompanyUser>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  late bool isPhone;
  int limit = (WidgetsBinding
              .instance.platformDispatcher.views.first.physicalSize.height /
          35)
      .toInt();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _companyBloc = context.read<CompanyBloc>();
    _userBloc = context.read<UserBloc>();
    switch (widget.role) {
      case Role.supplier:
        _companyUserBloc = context.read<CompanyUserSupplierBloc>()
            as CompanyUserBloc
          ..add(CompanyUserFetch(limit: limit));
        break;
      case Role.customer:
        _companyUserBloc = context.read<CompanyUserCustomerBloc>()
            as CompanyUserBloc
          ..add(CompanyUserFetch(limit: limit));
        break;
      case Role.lead:
        _companyUserBloc = context.read<CompanyUserLeadBloc>()
            as CompanyUserBloc
          ..add(CompanyUserFetch(limit: limit));
        break;
      default:
        _companyUserBloc = context.read<CompanyUserBloc>()
          ..add(CompanyUserFetch(limit: limit));
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Builder(builder: (BuildContext context) {
      Widget tableView() {
        if (companiesUsers.isEmpty) {
          return const Center(
              heightFactor: 20,
              child: Text("no companies/users found",
                  textAlign: TextAlign.center));
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
                                                child: companiesUsers[index - 1]
                                                            .type ==
                                                        PartyType.company
                                                    ? BlocProvider.value(
                                                        value: _companyBloc,
                                                        child: ShowCompanyDialog(
                                                            companiesUsers[index - 1]
                                                                .getCompany()!))
                                                    : BlocProvider.value(
                                                        value: _userBloc,
                                                        child: ShowUserDialog(
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
              context, '${state.message}', Colors.green);
        }
      }

      blocBuilder(context, state) {
        if (state.status == CompanyUserStatus.failure ||
            state.status == CompanyUserStatus.success) {
          companiesUsers = state.companiesUsers;
          hasReachedMax = state.hasReachedMax;
          return Scaffold(
              floatingActionButton: Column(
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
                              // search separate from finDocBloc
                              return BlocProvider.value(
                                  value: context
                                      .read<DataFetchBloc<CompaniesUsers>>(),
                                  child: const SearchCompanyUserList());
                            }).then((value) async => value != null
                            ?
                            // show detail page
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child: CompanyDialog(value));
                                })
                            : const SizedBox.shrink());
                      },
                      child: const Icon(Icons.search)),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                      key: const Key("addNewOrg"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _companyBloc,
                                  child: CompanyDialog(Company(
                                    role: widget.role,
                                  )));
                            });
                      },
                      tooltip: 'Add New',
                      child: const Column(
                        children: [Icon(Icons.add), Text('Org')],
                      )),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                      key: const Key("addNewPerson"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _userBloc,
                                  child: UserDialog(User(
                                    role: widget.role,
                                  )));
                            });
                      },
                      tooltip: 'Add New',
                      child: const Column(
                        children: [Icon(Icons.add), Text('Person')],
                      )),
                ],
              ),
              body: tableView());
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
