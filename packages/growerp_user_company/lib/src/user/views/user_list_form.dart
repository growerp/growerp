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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import '../../api_repository.dart';
import '../blocs/blocs.dart';
import '../views/views.dart';
import '../widgets/widgets.dart';

class UserListForm extends StatelessWidget {
  final Role? role;
  const UserListForm({
    super.key,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    CompanyUserAPIRepository companyUserAPIRepository =
        CompanyUserAPIRepository(
            context.read<AuthBloc>().state.authenticate!.apiKey!);
    Widget userList = RepositoryProvider.value(
        value: companyUserAPIRepository,
        child: UserList(
          key: key,
          role: role,
        ));
    switch (role) {
      case Role.lead:
        return BlocProvider<LeadBloc>(
            create: (context) => UserBloc(companyUserAPIRepository, role)
              ..add(const UserFetch()),
            child: userList);
      case Role.customer:
        return BlocProvider<CustomerBloc>(
            create: (context) => UserBloc(companyUserAPIRepository, role)
              ..add(const UserFetch()),
            child: userList);
      case Role.supplier:
        return BlocProvider<SupplierBloc>(
            create: (context) => UserBloc(companyUserAPIRepository, role)
              ..add(const UserFetch()),
            child: userList);
      case Role.company:
        return BlocProvider<EmployeeBloc>(
            create: (context) => UserBloc(companyUserAPIRepository, role)
              ..add(const UserFetch()),
            child: userList);
      default:
        return BlocProvider<UserBloc>(
            create: (context) => UserBloc(companyUserAPIRepository, role)
              ..add(const UserFetch()),
            child: userList);
    }
  }
}

class UserList extends StatefulWidget {
  const UserList({super.key, required this.role});

  final Role? role;

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 200.0;
  late UserBloc _userBloc;
  late CompanyUserAPIRepository repos;
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
    repos = context.read<CompanyUserAPIRepository>();
    switch (widget.role) {
      case Role.company:
        _userBloc = context.read<EmployeeBloc>() as UserBloc;
        break;
      case Role.supplier:
        _userBloc = context.read<SupplierBloc>() as UserBloc;
        break;
      case Role.customer:
        _userBloc = context.read<CustomerBloc>() as UserBloc;
        break;
      case Role.lead:
        _userBloc = context.read<LeadBloc>() as UserBloc;
        break;
      default:
        _userBloc = context.read<UserBloc>();
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
                        role: widget.role,
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
                        child: RepositoryProvider.value(
                            value: repos,
                            child: BlocProvider.value(
                                value: _userBloc,
                                child: UserListItem(
                                    user: users[index],
                                    index: index,
                                    role: widget.role,
                                    isDeskTop: !isPhone))));
              },
            ));
      }

      blocListener(context, state) {
/*        if (state.status == UserStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == UserStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
*/
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
              floatingActionButton: FloatingActionButton(
                  key: const Key("addNew"),
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return RepositoryProvider.value(
                              value: repos,
                              child: BlocProvider.value(
                                  value: _userBloc,
                                  child: UserDialog(User(
                                      company: Company(
                                    role: widget.role,
                                  )))));
                        });
                  },
                  tooltip: 'Add New',
                  child: const Icon(Icons.add)),
              body: showForm(state));
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
