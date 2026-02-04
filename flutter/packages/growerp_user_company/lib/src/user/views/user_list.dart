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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_user_company.dart';
import 'user_list_styled_data.dart';

class UserList extends StatefulWidget {
  const UserList({super.key, this.role});
  final Role? role;

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final double _scrollThreshold = 100.0;
  late UserBloc _userBloc;
  late AuthBloc _authBloc;
  late UserCompanyLocalizations _localizations;
  List<User> users = const <User>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  bool _isLoading = true;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _authBloc = context.read<AuthBloc>();
    switch (widget.role) {
      case Role.company:
        _userBloc = (context.read<EmployeeBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.supplier:
        _userBloc = (context.read<SupplierBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.customer:
        _userBloc = (context.read<CustomerBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.lead:
        (_userBloc = context.read<LeadBloc>() as UserBloc).add(
          const UserFetch(refresh: true),
        );
        break;
      default:
        _userBloc = (context.read<UserBloc>())
          ..add(const UserFetch(refresh: true));
    }
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = UserCompanyLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    return Builder(
      builder: (BuildContext context) {
        final isPhone = ResponsiveBreakpoints.of(context).isMobile;

        Widget tableView() {
          // Build rows for StyledDataTable
          final rows = users.map((user) {
            final index = users.indexOf(user);
            return getUserListRow(
              context: context,
              user: user,
              index: index,
              bloc: _userBloc,
              role: widget.role,
            );
          }).toList();

          return StyledDataTable(
            columns: getUserListColumns(context, role: widget.role),
            rows: rows,
            isLoading: _isLoading && users.isEmpty,
            scrollController: _scrollController,
            rowHeight: isPhone ? 72 : 56,
            onRowTap: (index) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return Dismissible(
                    key: const Key('userItem'),
                    direction: DismissDirection.startToEnd,
                    child: BlocProvider.value(
                      value: _userBloc,
                      child: UserDialogStateFull(user: users[index]),
                    ),
                  );
                },
              );
            },
          );
        }

        blocListener(context, state) {
          if (state.status == UserStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == UserStatus.success) {
            final translatedMessage = state.message != null
                ? translateUserCompanyBlocMessage(
                    _localizations,
                    state.message!,
                  )
                : '';
            if (translatedMessage.isNotEmpty) {
              HelperFunctions.showMessage(
                context,
                translatedMessage,
                Colors.green,
              );
            }
          }
        }

        blocBuilder(context, state) {
          // Update loading state
          _isLoading = state.status == UserStatus.loading;

          if (state.status == UserStatus.failure) {
            return FatalErrorForm(
              message: "Could not load ${widget.role.toString()}s!",
            );
          }

          users = state.users;
          if (users.isNotEmpty && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(currentScroll);
                }
              });
            });
          }
          hasReachedMax = state.hasReachedMax;

          return Column(
            children: [
              // Filter bar with search
              ListFilterBar(
                searchHint: 'Search ${widget.role?.name ?? 'users'}...',
                searchController: _searchController,
                onSearchChanged: (value) {
                  searchString = value;
                  _userBloc.add(UserFetch(refresh: true, searchString: value));
                },
              ),
              // Main content area with StyledDataTable
              Expanded(
                child: Stack(
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
                          children: [
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
                                      child: UserDialogStateFull(
                                        user: User(
                                          role: widget.role,
                                          company: widget.role == Role.company
                                              ? _authBloc
                                                    .state
                                                    .authenticate!
                                                    .company
                                              : Company(role: widget.role),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              tooltip: _localizations.addNew,
                              child: const Icon(Icons.add),
                            ),
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
                                      value: _userBloc,
                                      child: const CompanyUserFilesDialog(),
                                    );
                                  },
                                );
                              },
                              tooltip: 'companies/users up/download',
                              child: const Icon(Icons.file_copy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        switch (widget.role) {
          case Role.lead:
            return BlocConsumer<LeadBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.customer:
            return BlocConsumer<CustomerBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.company:
            return BlocConsumer<EmployeeBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.supplier:
            return BlocConsumer<SupplierBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          default:
            return BlocConsumer<UserBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _userBloc.add(UserFetch(searchString: searchString));
    }
  }
}
