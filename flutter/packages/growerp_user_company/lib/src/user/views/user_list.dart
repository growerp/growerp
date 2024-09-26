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
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_user_company.dart';

class UserList extends StatefulWidget {
  const UserList({super.key, this.role});
  final Role? role;

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 200.0;
  late UserBloc _userBloc;
  late AuthBloc _authBloc;
  List<User> users = const <User>[];
  bool showSearchField = false;
  String searchString = '';
  bool isLoading = false;
  bool hasReachedMax = false;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _authBloc = context.read<AuthBloc>();
    switch (widget.role) {
      case Role.company:
        _userBloc = (context.read<EmployeeBloc>() as UserBloc)
          ..add(const UserFetch());
        break;
      case Role.supplier:
        _userBloc = (context.read<SupplierBloc>() as UserBloc)
          ..add(const UserFetch());
        break;
      case Role.customer:
        _userBloc = (context.read<CustomerBloc>() as UserBloc)
          ..add(const UserFetch());
        break;
      case Role.lead:
        (_userBloc = context.read<LeadBloc>() as UserBloc)
            .add(const UserFetch());
        break;
      default:
        _userBloc = (context.read<UserBloc>())..add(const UserFetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    return Builder(builder: (BuildContext context) {
      Widget tableView() {
        if (users.isEmpty) {
          return Center(
              heightFactor: 20,
              child: Text(
                  context.read<String>() == 'AppHealth'
                      ? 'No clients found'
                      : 'no ${widget.role?.name ?? ''} users found',
                  textAlign: TextAlign.center));
        }
        // get table data formatted for tableView
        var (
          List<List<TableViewCell>> tableViewCells,
          List<double> fieldWidths,
          double? rowHeight
        ) = get2dTableData<User>(getUserListTableData,
            bloc: _userBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: users,
            extra: widget.role);
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
                                        return index > users.length
                                            ? const BottomLoader()
                                            : Dismissible(
                                                key: const Key('locationItem'),
                                                direction:
                                                    DismissDirection.startToEnd,
                                                child: BlocProvider.value(
                                                    value: _userBloc,
                                                    child: UserDialogStateFull(
                                                        users[index - 1])));
                                      }))
                    }),
          pinnedRowCount: 1,
        );
      }

      blocListener(context, state) {
        if (state.status == UserStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == UserStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }

      blocBuilder(context, state) {
        if (state.status == UserStatus.failure) {
          return FatalErrorForm(
              message: "Could not load ${widget.role.toString()}s!");
        }
        if (state.status == UserStatus.success) {
          isLoading = false;
          users = state.users;
          hasReachedMax = state.hasReachedMax;
          return Scaffold(
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                      key: const Key("search"),
                      heroTag: "userBtn1",
                      onPressed: () async {
                        // find findoc id to show
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              // search separate from finDocBloc
                              return BlocProvider.value(
                                  value: context.read<DataFetchBloc<Users>>(),
                                  child: const SearchUserList());
                            }).then((value) async => value != null
                            ?
                            // show detail page
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _userBloc,
                                      child: UserDialog(value));
                                })
                            : const SizedBox.shrink());
                      },
                      child: const Icon(Icons.search)),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                      key: const Key("addNewUser"),
                      heroTag: "userBtn2",
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _userBloc,
                                  child: UserDialog(User(
                                      role: widget.role,
                                      company: widget.role == Role.company
                                          ? _authBloc
                                              .state.authenticate!.company
                                          : Company(
                                              role: widget.role,
                                            ))));
                            });
                      },
                      tooltip: 'Add New',
                      child: const Icon(Icons.add)),
                ],
              ),
              body: tableView());
        }
        isLoading = true;
        return const LoadingIndicator();
      }

      switch (widget.role) {
        case Role.lead:
          return BlocConsumer<LeadBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case Role.customer:
          return BlocConsumer<CustomerBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case Role.company:
          return BlocConsumer<EmployeeBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case Role.supplier:
          return BlocConsumer<SupplierBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        default:
          return BlocConsumer<UserBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _userBloc.add(UserFetch(searchString: searchString));
    }
  }
}
