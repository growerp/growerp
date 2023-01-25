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
import '../../common/functions/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../domains.dart';

import '../../../api_repository.dart';

class UserListForm extends StatelessWidget {
  final UserGroup userGroup;
  const UserListForm({
    super.key,
    required this.userGroup,
  });

  @override
  Widget build(BuildContext context) {
    Widget userList = UserList(
      key: key,
      userGroup: userGroup,
    );
    switch (userGroup) {
      case UserGroup.Lead:
        return BlocProvider<LeadBloc>(
            create: (context) => UserBloc(context.read<APIRepository>(),
                userGroup, context.read<AuthBloc>())
              ..add(const UserFetch()),
            child: userList);
      case UserGroup.Customer:
        return BlocProvider<CustomerBloc>(
            create: (context) => UserBloc(context.read<APIRepository>(),
                userGroup, context.read<AuthBloc>())
              ..add(const UserFetch()),
            child: userList);
      case UserGroup.Supplier:
        return BlocProvider<SupplierBloc>(
            create: (context) => UserBloc(context.read<APIRepository>(),
                userGroup, context.read<AuthBloc>())
              ..add(const UserFetch()),
            child: userList);
      case UserGroup.Employee:
        return BlocProvider<EmployeeBloc>(
            create: (context) => UserBloc(context.read<APIRepository>(),
                userGroup, context.read<AuthBloc>())
              ..add(const UserFetch()),
            child: userList);
      case UserGroup.Admin:
        return BlocProvider<AdminBloc>(
            create: (context) => UserBloc(context.read<APIRepository>(),
                userGroup, context.read<AuthBloc>())
              ..add(const UserFetch()),
            child: userList);
      default:
        return Center(child: Text("user usergroup: '$userGroup' not allowed"));
    }
  }
}

class UserList extends StatefulWidget {
  const UserList({super.key, required this.userGroup});

  final UserGroup userGroup;

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 200.0;
  late UserBloc _userBloc;
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
    switch (widget.userGroup) {
      case UserGroup.Admin:
        _userBloc = context.read<AdminBloc>() as UserBloc;
        break;
      case UserGroup.Employee:
        _userBloc = context.read<EmployeeBloc>() as UserBloc;
        break;
      case UserGroup.Supplier:
        _userBloc = context.read<SupplierBloc>() as UserBloc;
        break;
      case UserGroup.Customer:
        _userBloc = context.read<CustomerBloc>() as UserBloc;
        break;
      case UserGroup.Lead:
        _userBloc = context.read<LeadBloc>() as UserBloc;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return Builder(builder: (BuildContext context) {
      Widget showForm(state) {
        return RefreshIndicator(
            onRefresh: (() async =>
                _userBloc.add(const UserFetch(refresh: true))),
            child: ListView.builder(
              key: const Key('listView'),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: hasReachedMax && users.isNotEmpty
                  ? users.length + 1
                  : users.length + 2,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(children: [
                    UserListHeader(
                        isPhone: isPhone,
                        userGroup: widget.userGroup,
                        userBloc: _userBloc),
                    const Divider(color: Colors.black),
                  ]);
                }
                if (index == 1 && users.isEmpty) {
                  return const Center(
                      heightFactor: 20,
                      child: Text("no records found!",
                          key: Key('empty'), textAlign: TextAlign.center));
                }
                index -= 1;
                return index >= users.length
                    ? const BottomLoader()
                    : Dismissible(
                        key: const Key('userItem'),
                        direction: DismissDirection.startToEnd,
                        child: UserListItem(
                            user: users[index],
                            index: index,
                            userGroup: widget.userGroup,
                            userBloc: _userBloc,
                            isDeskTop: !isPhone));
              },
            ));
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
              message: "Could not load ${widget.userGroup.toString()}s!");
        }
        if (state.status == UserStatus.success) {
          isLoading = false;
          users = state.users;
          hasReachedMax = state.hasReachedMax;
          return Scaffold(
              floatingActionButton: FloatingActionButton(
                  key: const Key("addNew"),
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                              value: _userBloc,
                              child: UserDialog(
                                  user: User(
                                userGroup: widget.userGroup,
                              )));
                        });
                  },
                  tooltip: 'Add New',
                  child: const Icon(Icons.add)),
              body: showForm(state));
        }
        isLoading = true;
        return const LoadingIndicator();
      }

      switch (widget.userGroup) {
        case UserGroup.Lead:
          return BlocConsumer<LeadBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case UserGroup.Customer:
          return BlocConsumer<CustomerBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case UserGroup.Admin:
          return BlocConsumer<AdminBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case UserGroup.Employee:
          return BlocConsumer<EmployeeBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        case UserGroup.Supplier:
          return BlocConsumer<SupplierBloc, UserState>(
              listener: blocListener, builder: blocBuilder);
        default:
          return Center(
              child: Text(
                  "should NOT show this for userGroup: ${widget.userGroup}"));
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
